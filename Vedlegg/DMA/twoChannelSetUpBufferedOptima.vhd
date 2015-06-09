library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity twoChannelSetUpBufferedOptima is
	generic(
		n: integer := 32; -- Sets data and addresses
		m: integer := 32; -- Sets count
		i: integer := 34;
		b: integer := 3
	);
	
	-- Includes: Data buffer, comparator, 2 channels and arbiter 
	port (
		-- Clock & reset
		clk : in std_logic;
		reset : in std_logic;
		-- Input from DMA Main Controller, to channels
		set0 : in std_logic; -- Used to select and set channel 0
		set1 : in std_logic; -- Used to select and set channel 1
		LModeIn0 : in std_logic; -- Sets loading mode in channel 0
		LModeIn1 : in std_logic; -- Sets loading mode in channel 1
		SModeIn0 : in std_logic; -- Sets storing mode in channel 0
		SModeIn1 : in std_logic; -- Sets storing mode in channel 1
		FSrcIn0 : in std_logic_vector(n-1 downto 0); -- Sets FSrc i channel 0
		FSrcIn1 : in std_logic_vector(n-1 downto 0); -- Sets FSrc i channel 1
		FDestIn0 : in std_logic_vector(n-1 downto 0); -- Sets FDest in channel 0
		FDestIn1 : in std_logic_vector(n-1 downto 0); -- Sets FDest in channel 1
		byteCountIn0 : in std_logic_vector(m-1 downto 0); -- Sets byteCounter in channel 0
		byteCountIn1 : in std_logic_vector(m-1 downto 0); -- Sets byteCounter in channel 1
		twistIn0 : in std_logic;
		twistIn1 : in std_logic;
		
		-- Input from administrating environment. Currently not in use
		--interruptReq : in std_logic; -- Requests arbiter for access
		--interruptCmd : in std_logic_vector(i-1 downto 0); -- Contains details of interrupt to the arbiter
		
		-- Input from system to data buffer
		dataIn : in std_logic_vector(n-1 downto 0); -- Next data
		srcIDIn : in std_logic_vector(n-1 downto 0); -- Next data's loadID
		pushData : in std_logic;
		
		-- Input from system to arbiter (assumingly from an output buffer that may get overfed of data)
		blockArbiter : in std_logic;
		
		-- Output from arbiter
		detailsOutput : out std_logic_vector(i+b-1 downto 0); -- Cmd + adr + 3 flags
		dataOutput : out std_logic_vector(n-1 downto 0);	-- Data for store cmd, or just 0's
		IDOut : out std_logic;
		
		-- Output from system to receiving buffer at bus system
		storeOutput : out std_logic;
		
		-- Output from channels to DMA Main Controller
		active0 : out std_logic;
		active1 : out std_logic;
		
		
		--interruptAck : out std_logic; -- Ack signal to the DMA Controller from arbiter
		
		-- Output from fifo
		bufferFull : out std_logic
		
		);
end twoChannelSetUpBufferedOptima;

 architecture arch of twoChannelSetUpBufferedOptima is
	-- Input buffer signals, for the channels
	signal set0_buffered : std_logic := '0';
	signal set1_buffered : std_logic := '0';
	
	signal internal_active0 : std_logic := '0';
	signal internal_active1 : std_logic := '0';
	
	signal LModeIn_buffered0 : std_logic := '0';
	signal LModeIn_buffered1 : std_logic := '0';
	signal SModeIn_buffered0 : std_logic := '0';
	signal SModeIn_buffered1 : std_logic := '0';
	signal FSrcIn_buffered0 : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');
	signal FSrcIn_buffered1 : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');
	signal FDestIn_buffered0 : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');
	signal FDestIn_buffered1 : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');
	signal byteCountIn_buffered0 : std_logic_vector(m-1 downto 0) := (m-1 downto 0 => '0');
	signal byteCountIn_buffered1 : std_logic_vector(m-1 downto 0) := (m-1 downto 0 => '0');
	signal twistIn_buffered0 : std_logic := '0';
	signal twistIn_buffered1 : std_logic := '0';
	
	-- Internal signals
	
	-- Between channels and fifo data buffer/LoadIDComparator
	signal currentSrcID : std_logic_vector(n-1 downto 0);
	signal srcID0 : std_logic_vector(n-1 downto 0); -- Store channel 0's FSrc, compared to current srcID in buffer
	signal srcID1 : std_logic_vector(n-1 downto 0); -- Channel 1's version of srcID0. NOTE: Same goes for rest with number 1 at the end of signal names.
	signal rdy0 : std_logic; -- Signal from srcIDComparator to channel 0, notifies that next data belongs to channel 0's next store (this is the dataRdy signals used for requesting store)
	signal rdy1 : std_logic;
	signal totalRdy : std_logic; -- Used for OR-ing rdy-signals
	
	-- Between channels and arbiter, LOAD:
	signal loadReq0 : std_logic; -- Request arbiter for passing through load cmd + src address
	signal loadReq1 : std_logic;
	signal loadAck0 : std_logic; -- Arbiter grants channel 0 access to pass load details. Intertal load channel counter decrements.
	signal loadAck1 : std_logic;
	signal loadAdr0 : std_logic_vector(i-1 downto 0); -- Load cmd + src address from channel 0 to arbiter
	signal loadAdrFull0 : std_logic_vector(i+b-1 downto 0); -- Load cmd + src address + flags from channel 0 to arbiter
	signal loadAdr1 : std_logic_vector(i-1 downto 0);
	signal loadAdrFull1 : std_logic_vector(i+b-1 downto 0);
	
	-- Between channels and arbiter, STORE:
	signal storeReq0 : std_logic; -- Request arbiter for passing through store cmd + dest address
	signal storeReq1 : std_logic;
	signal storeAck0 : std_logic; -- Arbiter grants channel 0 access to pass store details. Intertal store channel counter decrements.
	signal storeAck1 : std_logic;
	signal totalStoreAck : std_logic; -- Used for combinatorics
	signal storeAdr0 : std_logic_vector(i-1 downto 0); -- Store cmd + dest address from channel 0 to arbiter
	signal storeAdr1 : std_logic_vector(i-1 downto 0); 
	signal storeAdrFull0 : std_logic_vector(i+b-1 downto 0); -- Store cmd + dest address + FLAGS from channel 0 to arbiter
	signal storeAdrFull1 : std_logic_vector(i+b-1 downto 0);
	signal sFlags0 : std_logic_vector(b-1 downto 0);
	signal sFlags1 : std_logic_vector(b-1 downto 0);
	
	-- Concatinated fifo-signals
	signal fifoIn : std_logic_vector((n*2)-1 downto 0); -- loadIDIn & dataIn
	signal fifoOut : std_logic_vector((n*2)-1 downto 0); -- currentLoadID & data
	
	-- Between fifo-buffer and arbiter
	signal data : std_logic_vector (n-1 downto 0); -- Data transfered from shared data buffer to the arbiter. Will usually pass through during a store
	signal popData : std_logic; -- Set-signal from arbiter, used to update buffer with next ready data (sent during a store, at same time as data passes through)
	
	-- From system to/from fifo buffer
    signal popFirst : std_logic := '0'; -- Pop-signal, used to pop first data in a new series of arrivals. Stored in register
	signal bufferEmpty : std_logic := '0';
	
	-- From topview to DMA Main controller
	signal loadActive0 : std_logic := '0'; -- These interal signals will be combined using OR function. 
	signal loadActive1 : std_logic := '0';
	
	signal storeActive0 : std_logic := '0';
	signal storeActive1 : std_logic := '0';
	
	-- Output signal used internally
	--signal interruptAckSignal : std_logic := '0';
	
	--signal active0 : std_logic := '0';
	--signal active1 : std_logic := '0';
	
	--signal empty : std_logic := '0';
	--signal empty34 : std_logic_vector(33 downto 0) := (33 downto 0 => '0');
	
	-- Used components:
	component fifo
	generic(
		depth : natural := 16;
		width : natural := 64
	);
	port(
		-- Control lines:
		clk   : in std_logic;
		reset : in std_logic;

		-- Status lines:
		full  : out std_logic;
		empty : out std_logic;

		-- Data in:
		input : in std_logic_vector(width - 1 downto 0);
		push  : in std_logic;

		-- Data out:
		output : out std_logic_vector(width - 1 downto 0);
		pop    : in  std_logic
	);
	end component;
	
	component srcIDComparator
	port(  
		-- Input from fifo						   
		srcIDIn : in std_logic_vector(n-1 downto 0);
		
		-- Input from channels
		srcIDCheck0 : in std_logic_vector(n-1 downto 0);
		srcIDCheck1 : in std_logic_vector(n-1 downto 0);
		
		-- Output to channels
		rdy0 : out std_logic;
		rdy1 : out std_logic
	);
	end component;
	
	component fullChannel
	generic(
            n: integer := 32;
            m: integer := 32;
            b: integer := 3
        );
        
        -- Combines both load and store channel
        port (
            -- Clock
            clk : in std_logic;
            reset : in std_logic;
            -- Transfer administration input
            set : in std_logic; -- Activates setting registers in channel
            LModeIn : in std_logic; -- Input used to set counter behaviour (fixed address vs. changing address. Will always be set statically to '1' for this project)
            SModeIn : in std_logic;
            FSrcIn: in std_logic_vector(n-1 downto 0); -- Input data to FSrc
            FDestIn: in std_logic_vector(n-1 downto 0); -- Input data to FDest
            byteCountIn: in std_logic_vector(m-1 downto 0); -- Input data to byteCounter
            twistIn : in std_logic;
            
            -- Input from shared data buffer
            dataRdy : in std_logic; -- When data in shared data buffer belongs to this channel (identified by the data address)
            
            -- Input from arbiter
            loadAck : in std_logic;  
            storeAck : in std_logic; 
            
            -- Output to environment
            active : out std_logic;
            
            -- Output to shared data buffer
            srcIDOut : out std_logic_vector(n-1 downto 0); -- To compare with shared data buffer
            
            -- Output to arbiter
            srcOut : out std_logic_vector(2+(n-1) downto 0); -- Current src address for load request
            destOut : out std_logic_vector(2+(n-1) downto 0); -- Current dest address for store request
            loadReq : out std_logic;
            storeReq : out std_logic; -- Request signal to arbiter to pass through store address to arbiter (will be passed together with data from shared buffer)
            storeFlagsOut : out std_logic_vector(b-1 downto 0)
            
            );
	end component;
	
	component arbiterTop
	port(
 		-- INPUTS
 		clk : in STD_LOGIC;
 		-- Signals from Channels + block system
		blockReq : in std_logic;
		interruptReq : in std_logic;
		storeReq0: in std_logic;
		storeReq1: in std_logic;
		loadReq0: in std_logic;
		loadReq1: in std_logic;
		-- From buffer
		data_in : in STD_LOGIC_VECTOR(m-1 downto 0);
		-- Input from potential DMA Main Controller. Currently excluded in current version, may be reused in later expansion
		interruptInput : in std_logic_vector(i+b-1 downto 0);
		
		-- Inputs from channels
		storeInput0: in std_logic_vector(i+b-1 downto 0);
		storeInput1: in std_logic_vector(i+b-1 downto 0);
		loadInput0: in std_logic_vector(i+b-1 downto 0);
		loadInput1: in std_logic_vector(i+b-1 downto 0);
	
		--OUTPUTS
		-- To the channels
		interruptAck : out std_logic;
		storeAck0 : out std_logic; -- Also to buffer
		storeAck1 : out std_logic; -- Also to buffer
		loadAck0 : out std_logic;
		loadAck1 : out std_logic;
		
		-- Final output to the system
		adrOut : out std_logic_vector(i+b-1 downto 0);
		dataOut : out std_logic_vector(m-1 downto 0)
		
	);
	end component;
	
begin
	
	-- Assumption: Data fifo buffer does not receive data faster than what is sent out, due to slow memory system
	buffered : fifo
	port map(
		clk => clk,
		reset => reset,		 
							 
		full  => bufferFull,
		empty => bufferEmpty,

		-- Data in:
		input => fifoIn,
		push => pushData,

		-- Data out:
		output => fifoOut,
		pop    => popData
	);
	
	comparator : srcIDComparator
	port map(
		 srcIDIn => currentSrcID,
		
		-- Input from channels
		srcIDCheck0 => srcID0,
		srcIDCheck1 => srcID1,
		
		-- Output to channels
		rdy0 => rdy0,
		rdy1 => rdy1
	
	);
	
	channel0 : fullChannel	   
	port map(
		        clk => clk,
                reset => reset,
                
                set => set0_buffered,
                LModeIn => LModeIn_buffered0,
                SModeIn => SModeIn_buffered0,
                FSrcIn => FSrcIn_buffered0,
                FDestIn => FDestIn_buffered0,
                byteCountIn => byteCountIn_buffered0,
                twistIn => twistIn_buffered0,
                
                dataRdy => rdy0,
                
                loadAck => loadAck0,
                storeAck => storeAck0,
                
                active => internal_active0,
                
                srcIDOut => srcID0,
                
                srcOut => loadAdr0,
                destOut => storeAdr0,
                loadReq => loadReq0,
                storeReq => storeReq0,
                storeFlagsOut => sFlags0
	);
	
	channel1 : fullChannel
	port map(
		           clk => clk,
                   reset => reset,
                   
                   set => set1_buffered,
                   LModeIn => LModeIn_buffered1,
                   SModeIn => SModeIn_buffered1,
                   FSrcIn => FSrcIn_buffered1,
                   FDestIn => FDestIn_buffered1,
                   byteCountIn => byteCountIn_buffered1,
                   twistIn => twistIn_buffered1,
                   
                   dataRdy => rdy1,
                   
                   loadAck => loadAck1,
                   storeAck => storeAck1,
                   
                   active => internal_active1,
                   
                   srcIDOut => srcID1,
                   
                   srcOut => loadAdr1,
                   destOut => storeAdr1,
                   loadReq => loadReq1,
                   storeReq => storeReq1,
                   storeFlagsOut => sFlags1
	);
	
	arbiter : arbiterTop
	port map(
		clk => clk,
		-- From outside
		blockReq => blockArbiter,
		interruptReq => '0',
		-- Signals from channels
		storeReq0 => storeReq0,
		storeReq1 => storeReq1,
		loadReq0 => loadReq0,
		loadReq1 => loadReq1,
		-- From buffer
		data_in => data,
		-- From DMA Controller
		interruptInput => (36 downto 0 => '0'),
		-- Inputs from channels
		storeInput0 => storeAdrFull0,
		storeInput1 => storeAdrFull1,
		loadInput0 => loadAdrFull0,
		loadInput1 => loadAdrFull1,
	
		--OUTPUTS
		-- To DMA Controller
		--interruptAck => interruptAckSignal,
		-- To the channels
		storeAck0 => storeAck0,
		storeAck1 => storeAck1,
		loadAck0 => loadAck0,
		loadAck1 => loadAck1,
		
		-- Final output to the system
		adrOut => detailsOutput,
		dataOut => dataOutput
		
	);
	
	--interruptAck <= interruptAckSignal;
	loadAdrFull0 <= loadAdr0 & "000";
	loadAdrFull1 <= loadAdr1 & "000";
	storeAdrFull0 <= storeAdr0 & sFlags0;
	storeAdrFull1 <= storeAdr1 & sFlags1;
	
	fifoIn <= srcIDIn & dataIn;
    currentSrcID <= fifoOut((n*2)-1 downto n);
    data <= fifoOut(n-1 downto 0);
    
    -- Control enviroment may be designed to receive active-signals immediatly when setting a channel. 
    -- Since buffered channel setup has 1 extra cycle delay before a channel itself is set, contents from setX_buffered registers must be used as well. 
    -- In theory, setX-buffered should NEVER be active at same time as the channel's internal active signal
    active0 <= internal_active0 OR set0_buffered;
    active1 <= internal_active1 OR set1_buffered;    
	
	popData <= (totalStoreAck AND NOT bufferEmpty) OR popFirst; -- Whenever there is a store, the buffer must pop out next data EXCEPT when buffer is empty. 
	
	
	--storeOutput <= NOT reset AND (interruptAckSignal OR storeAck0 OR storeAck1 OR loadAck0 OR loadAck1); -- Whenever data passes through, bus output buffer must be notified
	storeOutput <= NOT reset AND (storeAck0 OR storeAck1 OR loadAck0 OR loadAck1); -- Whenever data passes through, bus output buffer must be notified
	
	totalRdy <= rdy0 OR rdy1;
    totalStoreAck <= storeAck0 OR storeAck1;
	-- When databuffer empty, if new arrival: Pop it at once!						   
	popFirstArrival : process(pushData, bufferEmpty, clk)
	begin
	   if rising_edge(clk) then
	       -- First data of arriving series to be popped. Arrival recognized by both pushData and BufferEmpty = 1.
	       -- Must not pop data if current last data to be stored by channels have been denied (blocked or interrupt, totalRdy = '1'),
	       -- May pop when done reading previous block of data or first load of all has arrived(totalRdy = '0'), 
	       -- or if data arrives at same time as store request has been acknowlegded (totalSToreAck = '1')
	       if pushData = '1' AND bufferEmpty = '1' AND (totalRdy = '0' OR totalStoreAck = '1') then 
	       
	           popFirst <= '1';
	       else 
	           popFirst <= '0';
	       end if;
	   end if;
	end process;
	
	-- UNIQUE FOR BUFFERED VERSION:
	synchronizeInputBuffers : process(clk, reset, set0, SModeIn0, LModeIn0, FSrcIn0, FDestIn0, byteCountIn0, twistIn0,
                                                  set1, SmodeIn1, LModeIn1, FSrcIn1, FDestIn1, byteCountIn1, twistIn1)
	begin
	   if rising_edge(clk) then
	       if reset = '1' then 
              set0_buffered <= '0';         
              set1_buffered <= '0';      
              LModeIn_buffered0 <= '0';
              LModeIn_buffered1 <= '0';
              SModeIn_buffered0 <= '0';  
              SModeIn_buffered1 <= '0';  
              FSrcIn_buffered0 <= (n-1 downto 0 => '0');    
              FSrcIn_buffered1 <= (n-1 downto 0 => '0');    
              FDestIn_buffered0 <= (n-1 downto 0 => '0');    
              FDestIn_buffered1 <= (n-1 downto 0 => '0');    
              byteCountIn_buffered0 <= (m-1 downto 0 => '0');
              byteCountIn_buffered1 <= (m-1 downto 0 => '0');
              twistIn_buffered0 <= '0';
              twistIn_buffered1 <= '0';
	       else
	          set0_buffered <= set0;         
              set1_buffered <= set1;      
              LModeIn_buffered0 <= LModeIn0;
              LModeIn_buffered1 <= LModeIn1;
              SModeIn_buffered0 <= SModeIn0;  
              SModeIn_buffered1 <= SModeIn1;  
              FSrcIn_buffered0 <= FSrcIn0;    
              FSrcIn_buffered1 <= FSrcIn1;    
              FDestIn_buffered0 <= FDestIn0;    
              FDestIn_buffered1 <= FDestIn1;    
              byteCountIn_buffered0 <= byteCountIn0;
              byteCountIn_buffered1 <= byteCountIn1;
              twistIn_buffered0 <= twistIn0;
              twistIn_buffered1 <= twistIn1;
            end if;
        end if;
	end process;
	
	-- WB Master needs the ID of a channel in case it is the last transfer, so that correct register can be cleared when done
	setIDOut : process(storeAck0, storeAck1)
	begin
	   if storeAck0 = '1' then
	       IDOut <= '0';
	   elsif storeAck1 = '1' then
	       IDOut <= '1';
	   else
	       IDOut <= '0';
	   end if;
	
	end process;
	
end arch;



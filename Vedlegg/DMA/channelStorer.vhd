library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity channelStorer is
	generic(
		n: integer := 32;
		m: integer := 32
	);
	port (
	    -- See Channel Loader for I/O description
		-- INPUTS
		-- Clock
		clk : in std_logic;
		reset : in std_logic;
		-- Transfer administration input
		set : in std_logic;       
		LModeIn : in std_logic;
		SModeIn : in std_logic; 
		FSrcIn: in std_logic_vector(n-1 downto 0); 
		FDestIn: in std_logic_vector(n-1 downto 0); 
		byteCountIn: in std_logic_vector(m-1 downto 0); 
		twistIn : in std_logic;
		-- From Data Buffer
		dataRdy : in std_logic; 
		-- From arbiter
		storeAck : in std_logic; 
	
		-- OUTPUT
		-- Transfer administration output
		storeActive : out std_logic; 
		-- To data buffer
		srcIDOut : out std_logic_vector((n-1) downto 0); 
		-- To arbiter
		destOut : out std_logic_vector(2+(n-1) downto 0); 
		storeReq : out std_logic;
		firstCountOut : out std_logic; -- Flag for first transfer 
		finalCountOut : out std_logic; -- Flag for final transfer
		twistOut : out std_logic
		
		);
end channelStorer;

architecture arch of channelStorer is
	
	-- Registers:
	signal LMode : std_logic := '1';
	signal SMode : std_logic := '1';
	signal FSrcAdr : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0'); -- FSrcAdr = Final Source Address. Used by ChannelStorer for identifying incoming data in shared data buffer.
	signal FDestAdr : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0'); -- FDestAdr = Final Destination Address. The value in the byteCounter will adjust to the current address.
	signal byteCounter : std_logic_vector(m-1 downto 0) := (m-1 downto 0 => '0'); -- Counter, used for both counting down and calculating src ID addresss and destination address.
	
	-- Internal combinatoric signals
	signal countInIncr : std_logic_vector(m-1 downto 0) := (m-1 downto 0 => '0'); -- byteCountIn incremented with one unit before storing on bytecounter
	signal countOutDcr : std_logic_vector(m-1 downto 0) := (m-1 downto 0 => '0'); -- counter output decremented with one unit, used to subtract both FSrc and FDest
	
	signal nextCount : std_logic_vector(m-1 downto 0) := (m-1 downto 0 => '0'); -- Next value for byteCounter, after decrementing with one unit. Happens when storing data is passed through arbiter (ACK = '1')
	
	signal currentAddress: std_logic_vector(n-1 downto 0) := (m-1 downto 0 => '0'); -- Result after subtracting FDestAdr with byteCounter, is to be concatinated with storeCommand
	signal storeCommand: std_logic_vector(1 downto 0) := "01";
	
	signal counterResult : std_logic := '0'; 
	signal countActive: std_logic := '0'; -- Input to byteCounter subtractor.
	
	-- Optima register
	signal twistEndianBytes : std_logic := '0'; -- Flag register for switching bytes in words from small Endian to big Endian
	signal firstCount       : std_logic := '0'; -- Flag register that signals when a store request is the first one for transfer. 
	                                            -- Needed by WB Master for 4-word transfers (128 bits), to set correct wb_sel_o, if first transfer is not aligned to first word.
	

    signal byteUnit : std_logic_vector(n-1 downto 0) := (31 downto 3 => '0') & "100";

	
	-- Used components:
	component adder
    port(
        input0: in std_logic_vector(n-1 downto 0);
        input1: in std_logic_vector(n-1 downto 0);
            
        result: out std_logic_vector(n-1 downto 0)
    );
    end component;
        
    component subtractor
    port(
        input0: in std_logic_vector(n-1 downto 0);
        input1: in std_logic_vector(n-1 downto 0);
                
        result: out std_logic_vector(n-1 downto 0)
    );
    end component;
	
	component manSubtractor
	port(
		opt : in std_logic;
		input0: in std_logic_vector(n-1 downto 0);
		input1: in std_logic_vector(n-1 downto 0);
	
		result: out std_logic_vector(n-1 downto 0)
		);
	
	end component;
	
	component countCheck
	port(
		count: in std_logic_vector(n-1 downto 0);
	
		result: out std_logic
		);
	end component;
	
begin
	
	-- Mapping all components in the channelStorer:
	
	-- Increasing counterinput by one unit in order to set the counter register with extra value (zero is done, 1 is final address, 1++ is before final address)
	countPlus : adder
    port map(
        input0 => byteCountIn,
        input1 => byteUnit,
            
        result => countInIncr
    );
        
        -- Decreasing value from counter with one before combining with FLA (remember, the extra value in counter is only to differentiate between final address and done)
    countMinus : subtractor
    port map(
        input0 => byteCounter,
        input1 => byteUnit,
            
        result => countOutDcr
    );
	
	-- Subtract FSrcAdr with current counter value (minus 1)
	FLAsubtractor : manSubtractor
	port map(
	   opt => LMode, -- Statically set to '1' for this project, may be expanded to include different modes for the future
		input0 => FSrcAdr,
		input1 => countOutDcr,
		
		result => srcIDOut
	);
	
	-- Subtract FDestAdr with current counter value (minus 1)
	FSAsubtractor : manSubtractor
	port map(
		opt => SMode, -- Statically set to '1' for this project, may be expanded to include different modes for the future
		input0 => FDestAdr,
		input1 => countOutDcr,
		
		result => currentAddress
	);
	
	-- Check if byteCounter > 0
	checker : countCheck
	port map(
		count => byteCounter,
		result => counterResult
	);
	
	-- Decrement byteCounter register with one unit, happens when storeAck = '1' (thus the current address is sent through the arbiter at the same time)
	counterDecrementation : manSubtractor
	port map(
		opt => countActive,
		input0 => byteCounter,
		input1 => byteUnit,
		
		result => nextCount
	);
	
	-- When using shared data buffer in the system, storeReq is linked directly to dataRdy from buffer, 
	-- since data is passed directly from buffer to arbiter, there is no futher need of registers or transfer loads.
	storeReq <= dataRdy AND NOT set;
	countActive <= counterResult AND storeAck;
	destOut <= storeCommand & currentAddress; -- Two first bits are used by any controller after arbiter to recognize load instructions (00 - Load, 01 - Store, 1- - Interrupt)
	
	storeActive <= counterResult;
	
	firstCountOut <= firstCount;
    twistOut <= twistEndianBytes;    
	
	-- Updating the registers: When set = '1', the DMA Main Controller sets the registers for new job 
	-- (should not happen as long as loadActive = '1', meaning that previous job is not done)
	-- When set = '0', the only update needed per clk is to reduce the counter register with 1 when loadAck is active (done by the nextCount signal)
	updateRegisters : process(clk, set, SModeIn, FSrcIn, FDestIn, twistIn, countInIncr, nextCount)
	begin
		if rising_edge(clk) then
		  if reset = '1' then
		      LMode <= '0';
		      SMode <= '0';
              FSrcAdr <= (n-1 downto 0 => '0');
              FDestAdr <= (n-1 downto 0 => '0');
              byteCounter <= (m-1 downto 0 => '0');
              twistEndianBytes <= '0';
	       elsif set = '1' then -- Set = '1' => Initialize the registers for next job
				LMode <= LModeIn;
				SMode <= SModeIn;
				FSrcAdr <= FSrcIn;
				FDestAdr <= FDestIn;
				byteCounter <= countInIncr;
				twistEndianBytes <= twistIn;
			else -- Set = '0' => Registers remain with same number, except counter that may decrement
				byteCounter <= nextCount;
			end if;
		else
			-- Nothing
		end if;
	end process; 
	
	
    setFinalCount : process (countOutDcr)
    begin
        if countOutDcr = (31 downto 0 => '0') then -- Has hit final address for transfer
            finalCountOut <= '1';
        else
            finalCountOut <= '0';
        end if;
    end process;
	
	setFirstCount : process (clk, reset, set, firstCount, storeAck)
	begin
	   if rising_edge(clk) then
	       if reset = '1' then
	           firstCount <= '0';
	       elsif (firstCount = '1' and storeAck = '0') or set = '1' then -- The first count is from when the channel is set up to transfer, and lasts until the first transfer is done (recognized by storeack)
	           firstCount <= '1';
	       else
	           firstCount <= '0';
	       end if;    
	       
	   
	   end if;
	end process;
	
	
	
end arch;



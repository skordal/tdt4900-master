library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity DMATopLevel is
	generic( n : integer := 32; -- 32-bit addresses
	         m : integer := 32;
			 u : integer := 96;	-- ReqDetails, 32 bit set as standard
			 p : integer := 64;
			 bufferDepth : integer := 8
	);
	
	port(
	   -- General inputs
	   clk : in std_logic;
	   reset : in std_logic;
	   
	   -- Inputs to request buffer
	   reqIn : in std_logic_vector(u-1 downto 0);
	   reqStore : in std_logic;
	   
	   -- Inputs to data buffer
	   dataIn : in std_logic_vector(p-1 downto 0);
	   dataStore : in std_logic;
	   
	   -- Input from output bus to channels
	   outputFull : in std_logic;
	   
	   -- Output from buffers
	   reqFull : out std_logic;
	   dataFull : out std_logic;
	   
	   -- Output from DMA
	   storeOutput : out std_logic;
	   detailsOut : out std_logic_vector((n+2)-1 downto 0);
	   dataOut : out std_logic_vector(n-1 downto 0);
	   AMOut : out std_logic
	   
	   );
end DMATopLevel;

architecture arch of DMATopLevel is
	
	-- Signals between Request FIFO and DMA Controller:
	signal fifoReqOut : std_logic_vector(u-1 downto 0) := (u-1 downto 0 => '0');
	signal fifoReqEmpty : std_logic := '1'; --NOTICE that default is high
	signal fifoReqPop : std_logic := '0';
	signal reqNewJob : std_logic := '0';
	signal reqUpdate : std_logic := '0';
	signal reqDetails : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');
	signal loadDetails : std_logic_vector(n-1 downto 0)  := (n-1 downto 0 => '0');
	signal storeDetails : std_logic_vector(n-1 downto 0)  := (n-1 downto 0 => '0');
	
	signal popFirst : std_logic; -- Helping signal, used to pop out first input from fifo-buffer, after first arrival (in a series of arrival)
	
    -- Signals between DMA controller and TwoChannelSetup
    signal set0 : std_logic := '0';
    signal set1 : std_logic := '0';
    signal mode : std_logic := '1'; -- NOTE: Always 1 for this project
    signal FLA : std_logic_vector (n-1 downto 0) := (n-1 downto 0 => '0');
    signal FSA : std_logic_vector (n-1 downto 0) := (n-1 downto 0 => '0');
    signal count : std_logic_vector (n-1 downto 0) := (n-1 downto 0 => '0');
    signal shiftedCount : std_logic_vector (n-1 downto 0) := (n-1 downto 0 => '0');
	signal interruptReq : std_logic := '0';
	signal interruptAck : std_logic := '0';
	signal interruptDetails : std_logic_vector((n+2)-1 downto 0) := ((n+2)-1 downto 0 => '0');
	signal decrement : std_logic_vector(2 downto 0) := "001";
	
	signal activeChannel0 : std_logic := '0';
	signal activeChannel1 : std_logic := '0';
	
	-- Input signal aliases for twoChannelSetup
	signal loadID : std_logic_vector((p/2)-1 downto 0) := ((p/2)-1 downto 0 => '0');
	signal data : std_logic_vector((p/2)-1 downto 0) := ((p/2)-1 downto 0 => '0');
	
	
	component fifo -- For requestbuffer. DMA Channel setup already has FIFO buffer for data
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
	
	component adapter
	port(
	    clk : in std_logic;
        emptyIn : in std_logic;
        reqUpdateIn : in std_logic;
           
        popOut : out std_logic;
        requestOut : out std_logic
	);
	end component;
	
	component DMAControllerSta
	generic( n : integer := 32; -- 32-bit addresses
                 m : integer := 32;    -- ReqDetails, 32 bit set as standard
                 i : integer := 2    -- 2-bit register
        );
        
        port(
            -- INPUTS
            -- Clock & reset
            clk : in STD_LOGIC;
            reset : in STD_LOGIC;
                                                                   
            -- From Request buffer
            req : in std_logic; -- New data ready from request buffer
            reqDetails : in std_logic_vector(m-1 downto 0);    -- Details, including requestor ID, count, mode
            loadDetails : in std_logic_vector(n-1 downto 0); -- Beginning load address
            storeDetails : in std_logic_vector(n-1 downto 0); -- Beginning store address
            -- From channels
            activeCh0 : in std_logic; -- Channel 0 signals active
            activeCh1 : in std_logic; -- Channel 1 signals active
            -- From arbiter
            interruptAck : in std_logic;     -- Access to interrupt output granted
            
            -- OUTPUTS
            -- To request buffer
            reqUpdate : out std_logic; --Signals buffer that data is read, and to prepare next data
            -- To Channels
            set0 : out std_logic; -- Set channel 0
            set1 : out std_logic; -- Set channel 1
            FLAOut : out std_logic_vector (n-1 downto 0); -- Final Load Address to channels
            FSAOut : out std_logic_vector (n-1 downto 0); -- Final Store Address to channels
            counterOut : out std_logic_vector (n-1 downto 0); -- Output to counter
            decrementOut : out std_logic_vector(2 downto 0);
            --LModeOut : out std_logic;    -- Set to 1 for this project
            --SModeOut : out std_logic; -- Set to 1 for this project
            -- To arbiter
            interruptReq : out std_logic;
            interruptDetails : out std_logic_vector((n-1)+2 downto 0)
            );
	end component;
	
	component twoChannelSetUpBuffered
	generic(
            n: integer := 32; -- Sets data and addresses
            m: integer := 32; -- Sets count
            i: integer := 34
        );
        
        -- Includes: Data buffer, 2 channels and arbiter 
        -- (inclusion of arbiter means that all signals between DMA Main Controller and arbiter must be sent throught this top view)
        port (
            -- Clock & reset
            clk : in std_logic;
            reset : in std_logic;
            -- Input from DMA Main Controller, to channels
            set0 : in std_logic; -- Used to select and set channel 0
            set1 : in std_logic; -- Used to select and set channel 1
            LModeIn : in std_logic; -- Sets loading mode in selected channel
            SModeIn : in std_logic; -- Sets storing mode in selected channel
            FLAIn : in std_logic_vector(n-1 downto 0); -- Sets FLAs i selected channel
            FSAIn : in std_logic_vector(n-1 downto 0); -- Sets FSA in selected channel
            countIn : in std_logic_vector(m-1 downto 0); -- Sets counter in selected channel
            decrementIn : in std_logic_vector(2 downto 0);
            -- Input from DMA Main Controller, directly to arbiter
            interruptReq : in std_logic; -- Requests arbiter for access
            interruptCmd : in std_logic_vector(i-1 downto 0); -- Contains details of interrupt to the arbiter
            
            -- Input from system to data buffer
            dataIn : in std_logic_vector(n-1 downto 0); -- Next data
            loadIDIn : in std_logic_vector(n-1 downto 0); -- Next data's loadID
            pushData : in std_logic;
            
            -- Input from system to arbiter (assumingly from an output buffer that may get overfed of data)
            blockArbiter : in std_logic;
            
            -- Output from arbiter
            detailsOutput : out std_logic_vector(i-1 downto 0); -- Interrupt details, store cmd + address, or load cmd + address
            dataOutput : out std_logic_vector(n-1 downto 0);    -- Data for store cmd, or just 0's
            AMOut : out std_logic;
            
            -- Output from system to receiving buffer at bus system
            storeOutput : out std_logic;
            
            -- Output from channels to DMA Main Controller
            active0 : out std_logic;
            active1 : out std_logic;
            
            
            interruptAck : out std_logic; -- Ack signal to the DMA Controller from arbiter
            
            -- Output from fifo
            bufferFull : out std_logic
            
            );
	end component;
	
begin 
	
	-- WARNING: STATIC SETUP HINDERS changes
	-- Set up signals
	-- Fifo request output
	loadDetails <= fifoReqOut(95 downto 64);
	storeDetails <= fifoReqOut(63 downto 32);
	reqDetails <= fifoReqOut(31 downto 0);
	--shiftedCount<= count (29 downto 0) & "00";
    -- Fifo-DMAController control signals, based on empty and pop
    --reqNewJob <= NOT fifoReqEmpty;
    --fifoReqPop <= (reqUpdate AND NOT fifoReqEmpty) OR popFirst;
    -- Mode in into channels
    mode <= '1';
    
    -- Data details
    loadID <= dataIn(63 downto 32);
    data <= dataIn(31 downto 0); 
    
    reqFifo : fifo
    generic map(
        width => u,
        depth => bufferDepth
    )
    port map(
        clk => clk,
        reset => reset,
        full => reqFull,
        empty => fifoReqEmpty,
        input => reqIn,
        push => reqStore,
        output => fifoReqOut,
        pop => fifoReqPop
    );
	
	FIFODMAControllerAdapter : adapter
	port map(
	   clk => clk,
	   emptyIn => fifoReqEmpty,
	   reqUpdateIn => reqUpdate,
	   
	   popOut => fifoReqPop,
	   requestOut => reqNewJob
	);
	
	controller : DMAControllerSta
	port map(
	   clk => clk,
	   reset => reset,
	   req => reqNewJob,
	   reqDetails => reqDetails,
	   loadDetails => loadDetails,
	   storeDetails => storeDetails,
	   
	   activeCh0 => activeChannel0,
	   activeCh1 => activeChannel1,
	   
	   interruptAck => interruptAck,
	   
	   reqUpdate => reqUpdate,
	   
	   set0 => set0,
	   set1 => set1,
	   FLAOut => FLA,
	   FSAOut => FSA,
	   counterOut => count,
	   decrementOut => decrement,
	   
	   interruptReq => interruptReq,
	   interruptDetails => interruptDetails
	);
	
    duoChannelWithArbiter : twoChannelSetUpBuffered
    port map(
        clk => clk,
        reset => reset,
        
        set0 => set0,
        set1 => set1,
        LModeIn => mode,
        SModeIn => mode,
        FLAIn => FLA,
        FSAIn => FSA,
        --countIn => shiftedCount,
        countIn => count,
        decrementIn => decrement,
        
        interruptReq => interruptReq,
        interruptCmd => interruptDetails,
        
        dataIn => data,
        loadIDIn => loadID,
        pushData => dataStore,
        
        blockArbiter => outputFull,
        
        detailsOutput => detailsOut,
        dataOutput => dataOut,
        storeOutput => storeOutput,
        AMOut => AMOut,
        
        active0 => activeChannel0,
        active1 => activeChannel1,
        
        interruptAck => interruptAck,
        bufferFull => dataFull
        
    );
	
end arch;
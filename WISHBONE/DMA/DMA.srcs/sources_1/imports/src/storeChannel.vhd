library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity storeChannel is
	generic(
		n: integer := 32;
		m: integer := 32
	);
	port (
		-- INPUTS
		-- Clock
		clk : in std_logic;
		reset : in std_logic;
		-- From DMA Main Controller
		set : in std_logic; 
		LModeIn : in std_logic;
		SModeIn : in std_logic; 
		FLAIn: in std_logic_vector(n-1 downto 0); 
		FSAIn: in std_logic_vector(n-1 downto 0); 
		countIn: in std_logic_vector(m-1 downto 0); 
		decrementIn: in std_logic_vector(2 downto 0);
		-- From Data Buffer
		dataRdy : in std_logic; 
		-- From arbiter
		storeAck : in std_logic; 
	
		-- OUTPUT
		-- To DMA Main Controller
		storeActive : out std_logic; 
		-- To data buffer
		loadAdrOut : out std_logic_vector((n-1) downto 0); 
		-- To arbiter
		storeAdrOut : out std_logic_vector(2+(n-1) downto 0); 
		storeReq : out std_logic; 
		
        -- MASTER: Output for addressing mode, needed for WB interface
        AMOut: out std_logic
		
		);
end storeChannel;

architecture arch of storeChannel is
	
	-- Registers:
	signal LMode : std_logic := '1';
	signal SMode : std_logic := '1';
	signal FLA : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0'); -- FLA = Final Load Address. Usually the final address for the loading. The value in the counter will adjust to the current address. In this case used for identifying the data in shared data buffer, as our own or not.
	signal FSA : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0'); -- FSA = Final Store Address. Usually the final address for the storing. The value in the vounter will adjust to the current address.
	signal counter : std_logic_vector(m-1 downto 0) := (m-1 downto 0 => '0'); -- Counter, used to both decrement FLA to current address, and used to know when job is done (therefore incremented with extra 1 when set, and which output is subtracted with 1 before combining with FLA)
	
	-- Internal combinatoric signals
	signal countInIncr : std_logic_vector(m-1 downto 0) := (m-1 downto 0 => '0'); -- countIn incremented with 1 before storing to counter (see comment on counter)
	signal countOutDcr : std_logic_vector(m-1 downto 0) := (m-1 downto 0 => '0'); -- counter output decremented with 1, used to subtract FLA
	
	signal nextCount : std_logic_vector(m-1 downto 0) := (m-1 downto 0 => '0'); -- Next value for counter, after decrementing with 1. Happens when data is passed through arbiter (ACK = '1')
	
	signal currentAddress: std_logic_vector(n-1 downto 0) := (m-1 downto 0 => '0'); -- Result after subtracting FSA with counter, is to be concatinated with storeCommand
	signal storeCommand: std_logic_vector(1 downto 0) := "01";
	
	signal counterResult : std_logic := '0'; 
	signal countActive: std_logic := '0'; -- Input to counter subtractor.
	
    -- MASTER THESIS:
    signal decrement: std_logic_vector(2 downto 0) := "001"; -- Standard is decrement by 1 for word-addressing	
    signal decrementInput: std_logic_vector (31 downto 0) := (31 downto 0 => '0');
    signal decrementReg : std_logic_vector (31 downto 0) := (31 downto 0 => '0');
	
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
	
	-- Mapping all components in the storeChannel:
	
	-- Incresing counterinput by one in order to set the counter register with extra value (zero is done, 1 is final address, 1++ is before final address)
	countPlus : adder
    port map(
        input0 => countIn,
        input1 => decrementInput,
            
        result => countInIncr
    );
        
        -- Decreasing value from counter with one before combining with FLA (remember, the extra value in counter is only to differentiate between final address and done)
    countMinus : subtractor
    port map(
        input0 => counter,
        input1 => decrementReg,
            
        result => countOutDcr
    );
	
	-- Subtract FLA with current counter value (minus 1)
	FLAsubtractor : manSubtractor
	port map(
	   opt => LMode, -- Always '1' for this project, may be expanded to include different modes for the future
		input0 => FLA,
		input1 => countOutDcr,
		
		result => loadAdrOut
	);
	
	-- Subtract FSA with current counter value (minus 1)
	FSAsubtractor : manSubtractor
	port map(
		opt => SMode, -- Always '1' for this project, may be expanded to include different modes for the future
		input0 => FSA,
		input1 => countOutDcr,
		
		result => currentAddress
	);
	
	-- Check if counter > 0
	checker : countCheck
	port map(
		count => counter,
		result => counterResult
	);
	
	-- Decrement counter register with 1, happens when loadAck = '1' (thus the current address is sent throug the arbiter at the same time)
	counterDecrementation : manSubtractor
	port map(
		opt => countActive,
		input0 => counter,
		input1 => decrementReg,
		--input1 => (n-1 downto 1 => '0') & '1', -- Should be "0...01"
		--input1 => (n-1 downto 3 => '0') & "100", -- Should be "0....100" = 4
	
		result => nextCount
	);
	
	-- In shared buffer scheme, storeReq is linked directly to dataRdy from buffer, since data is passed directly from buffer to arbiter, there is no futher need of registers or transfer loads.
	storeReq <= dataRdy AND NOT set;
	countActive <= counterResult AND storeAck;
	storeAdrOut <= storeCommand & currentAddress; -- Two first bits are used by any controller after arbiter to recognize load instructions (00 - Load, 01 - Store, 1- - Interrupt)
	
	storeActive <= counterResult;
	
	decrementInput <= (n-1 downto 3 => '0') & decrementIn;
    decrementReg <= (n-1 downto 3 => '0') & decrement;
	
	-- Updating the registers: When set = '1', the DMA Main Controller sets the registers for new job 
	-- (should not happen as long as loadActive = '1', meaning that previous job is not done)
	-- When set = '0', the only update needed per clk is to reduce the counter register with 1 when loadAck is active (done by the nextCount signal)
	updateRegisters : process(clk, set, SModeIn, FLAIn, FSAIn, countInIncr, nextCount)
	begin
		if rising_edge(clk) then
		  if reset = '1' then
		      LMode <= '0';
		      SMode <= '0';
              FLA <= (n-1 downto 0 => '0');
              FSA <= (n-1 downto 0 => '0');
              counter <= (m-1 downto 0 => '0');
              decrement <= "001";
	       elsif set = '1' then -- Set = '1' => Initialize the registers for next job
				LMode <= LModeIn;
				SMode <= SModeIn;
				FLA <= FLAIn;
				FSA <= FSAIn;
				counter <= countInIncr;
				decrement <= decrementIn;
			else -- Set = '0' => Registers remain with same number, except counter that may decrement
				counter <= nextCount;
			end if;
		else
			-- Nothing
		end if;
	end process; 
	
	
	--MASTER
    setAMOut : process(decrement)
    begin
        if decrement = "100" then
            AMOut <= '1';
        else 
            AMOut <= '0';
        end if;
    end process;
	
	
end arch;



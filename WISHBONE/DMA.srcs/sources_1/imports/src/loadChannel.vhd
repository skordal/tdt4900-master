library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity loadChannel is
	generic(
		n: integer := 32;
		m: integer := 32
	);
	port (
		-- Clock
		clk : in std_logic;
		reset : in std_logic;
		-- Input from DMA Main Controller
		set : in std_logic; -- Activates setting counter, final load address (and mode)
		LModeIn : in std_logic; -- Input used to set counter behaviour (fixed address vs. changing address. Will always be '1' for this project)
		FLAIn: in std_logic_vector(n-1 downto 0); -- Input data to FLA
		countIn: in std_logic_vector(m-1 downto 0); -- Input data to counter
		decrementIn: in std_logic_vector(2 downto 0);
		
		-- Input from arbiter
		loadAck : in std_logic; -- Receives ACK signal from arbiter, load data now goes through and counter is decremented
		
		-- Output to DMA MAin Controller (may be unnecessary, storeActive from Store Channel should suffice, since a transfer is not done until )
		loadActive : out std_logic; -- Load Channel is active, may be used by DMA Main Controller to determine if a channel is active.
		
		-- Output to Arbiter
		loadAdrOut : out std_logic_vector(2+(n-1) downto 0); -- Current load address
		loadReq : out std_logic -- Request signal to arbiter to pass through load data
		);
end loadChannel;

architecture arch of loadChannel is
	-- Registers:
	signal LMode : std_logic := '1';
	signal FLA : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0'); -- FLA = Final Load Address. Usually the final address for the loading. The value in the counter will adjust to the current address
	signal counter : std_logic_vector(m-1 downto 0) := (m-1 downto 0 => '0'); -- Counter, used to both decrement FLA to current address, and used to know when job is done (therefore incremented with extra 1 when set, and which output is subtracted with 1 before combining with FLA)
	
	-- Internal combinatoric signals
	signal countInIncr : std_logic_vector(m-1 downto 0) := (m-1 downto 0 => '0');-- countIn incremented with 1 before storing to counter (see comment on counter)
	signal countOutDcr : std_logic_vector(m-1 downto 0) := (m-1 downto 0 => '0'); -- counter output decremented with 1, used to subtract FLA
	
	signal nextCount : std_logic_vector(m-1 downto 0):= (m-1 downto 0 => '0'); -- Next value for counter, after decrementing with 1. Happens when data is passed through arbiter (ACK = '1')
	signal counterResult : std_logic := '0'; -- counter > 0, mapped to both loadReq and loadActive
	
	signal currentAddress: std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0'); -- Result after subtracting FLA with counter, is to be concatinated with loadCommand
	signal loadCommand: std_logic_vector(1 downto 0) := "00";
	signal countActive: std_logic := '0'; -- Input to counter subtractor.
	
	-- MASTER THESIS:
	signal decrement: std_logic_vector(2 downto 0) := "001"; -- Standard is decrement by 1 for word-addressing
	signal decrementInput : std_logic_vector(31 downto 0) := (31 downto 0 => '0'); -- Signal for concatinating with input decrement
	signal decrementReg : std_logic_vector(31 downto 0) := (31 downto 0 => '0'); -- Signal for concatinating with register decrement
	
	
	
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
	
	-- Mapping all components in the loadChannel:
	
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
		input1 => decrementReg, -- Should be "0.....01" = 1 or "0....100" = 4, depending on what DMA controller has set
		--input1 => (n-1 downto 1 => '0') & '1', -- Should be "0...01"
	    --input1 => (n-1 downto 3 => '0') & "100", -- Should be "0....100" = 4
	   
		result => nextCount
	);
	
	
	-- As long as set is active, no request should be sent out.
	-- Set should be deactive at this point, since loadActive is sent out the next clockcycle and Main Controller knows that channel is activated. 
	-- Still, to be sure, must avoid that set is active at same time as load request, or there may be confusion in the counter register
	-- if set is active at same time as the decrementor (due to loadAck). 
	countActive <= counterResult AND loadAck;
	loadReq <= counterResult AND NOT set; 
	loadActive <= counterResult;
	
	loadAdrOut <= loadCommand & currentAddress; -- Two first bits are used by any controller after arbiter to recognize load instructions (00 - Load, 01 - Store, 1- - Interrupt)
	
	decrementInput <= (n-1 downto 3 => '0') & decrementIn;
	decrementReg <= (n-1 downto 3 => '0') & decrement;
	
	-- Updating the registers: When set = '1', the DMA Main Controller sets the registers for new job 
	-- (should not happen as long as loadActive = '1', meaning that previous job is not done)
	-- When set = '0', the only update needed per clk is to reduce the counter register with 1 when loadAck is active (done by the nextCount signal)
	updateRegisters : process(clk, reset, set, LModeIn, FLAIn, countInIncr, nextCount)
	begin
		if rising_edge(clk) then
		  if reset = '1' then
		      LMode <= '0';
		      FLA <= (n-1 downto 0 => '0');
		      counter <= (m-1 downto 0 => '0');
		      decrement <= "001";
			elsif set = '1' then -- Set = '1' => Initialize the registers for next job
				LMode <= LModeIn;
				FLA <= FLAIn;
				counter <= countInIncr;
				decrement <= decrementIn;
			else -- Set = '0' => Registers remain with same number, except counter that may decrement
				counter <= nextCount;
			end if;
		else
			-- Nothing
		end if;
	end process; 
end arch;



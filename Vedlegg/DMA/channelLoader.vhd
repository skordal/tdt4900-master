library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity channelLoader is
	generic(
		n: integer := 32;
		m: integer := 32
	);
	port (
		-- Clock
		clk : in std_logic;
		reset : in std_logic;
		-- Transfer administration input
		set : in std_logic; -- Activates setting counter, final load address (and mode)
		LModeIn : in std_logic; -- Input used to set counter behaviour (fixed address vs. changing address. Is statically set to '1' for the master thesis project)
		FSrcIn: in std_logic_vector(n-1 downto 0); -- Input data to FSrcAdr
		byteCountIn: in std_logic_vector(m-1 downto 0); -- Input data to byteCounter
		-- Input from arbiter
		loadAck : in std_logic; -- Receives ACK signal from arbiter, load data now goes through and counter is decremented
		
		-- Transfer administration output
		loadActive : out std_logic; -- Load Channel is active, may be used by environment to determine if a channel is active.
		
		-- Output to Arbiter
		srcOut : out std_logic_vector(2+(n-1) downto 0); -- Current src address, from where data will be loaded
		loadReq : out std_logic -- Request signal to arbiter to pass through load command
		);
end channelLoader;

architecture arch of channelLoader is
	-- Registers:
	signal LMode : std_logic := '1';
	signal FSrcAdr : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0'); -- FSrcAdr = Final Source Address. The value in the byteCounter will adjust to the current address
	-- Counter, used to both keep track of the progress, and subtract FSrcAdr to current address. 
	-- Is usualy incremented with input with one more unit, and output is decremented with one unit before subtracting FSrcAdr.
	-- Zero (0) is finished, not final address.
    signal byteCounter : std_logic_vector(m-1 downto 0) := (m-1 downto 0 => '0'); 
	
	-- Internal combinatoric signals
	signal countInIncr : std_logic_vector(m-1 downto 0) := (m-1 downto 0 => '0');-- byteCountIn incremented with 1 before storing to byteCounter (see comment on counter)
	signal countOutDcr : std_logic_vector(m-1 downto 0) := (m-1 downto 0 => '0'); -- counter output decremented with 1, before used in subtraction with FSrcAdr
	
	signal nextCount : std_logic_vector(m-1 downto 0):= (m-1 downto 0 => '0'); -- Next value for counter, after decrementing with one unit. Happens when data is passed through arbiter (ACK = '1')
	signal counterResult : std_logic := '0'; -- byteCounter > 0, mapped to both loadReq and loadActive
	
	signal currentAddress: std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0'); -- Result after subtracting FSrcAdr with counter, is to be concatinated with loadCommand
	signal loadCommand: std_logic_vector(1 downto 0) := "00";
	signal countActive: std_logic := '0'; -- Input to counter subtractor.
	
	
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
	
	-- Mapping all components in the channelLoader:
	
	-- Increasing counterinput by one unit in order to set the counter register with extra value (zero is finished, 1 is final address, 1++ is before final address)
	countPlus : adder
	port map(
		input0 => byteCountIn,
		input1 => byteUnit,
		
		result => countInIncr
	);
	
	-- Decreasing value from counter with one before subtracting FSrcAdr with it (remember, the extra value in counter is only to differentiate between final address and done)
	countMinus : subtractor
	port map(
		input0 => byteCounter,
		input1 => byteUnit,
		
		result => countOutDcr
	);
	
	-- Subtract FSrcAdr with current byteCounter value (minus one unit)
	FSrcAdrSubtractor : manSubtractor
	port map(
		opt => LMode, -- Statically set to '1' for this project, may be expanded to include different modes for the future
		input0 => FSrcAdr,
		input1 => countOutDcr,
		
		result => currentAddress
	);
	
	-- Check if byteCounter > 0
	checker : countCheck
	port map(
		count => byteCounter,
		result => counterResult
	);
	
	-- Decrement counter register with one unit, happens when loadAck = '1' (thus the current address is sent throug the arbiter at the same time)
	counterDecrementation : manSubtractor
	port map(
		opt => countActive,
		input0 => byteCounter,
		input1 => byteUnit,
		
		result => nextCount
	);
	
	
	-- As long as set is active, no request should be sent out.
	-- Set should not be active when requesting load, or confusion in byteCounter register may happen if both set and loadack are active.
	countActive <= counterResult AND loadAck;
	loadReq <= counterResult AND NOT set; 
	loadActive <= counterResult;
	
	srcOut <= loadCommand & currentAddress; -- Two first bits are used by WB Master after arbiter to recognize load instructions (00 - Load, 01 - Store)
	
	
	-- Updating the registers: When set = '1', the environment sets the registers for new transfer 
	-- (should not happen as long as loadActive = '1', meaning that previous transfer is not done)
	-- When set = '0', the only update needed per clk is to reduce the byteCounter register with one unit when loadAck is active (done by the nextCount signal)
	updateRegisters : process(clk, reset, set, LModeIn, FSrcIn, countInIncr, nextCount)
	begin
		if rising_edge(clk) then
		  if reset = '1' then
		      LMode <= '0';
		      FSrcAdr <= (n-1 downto 0 => '0');
		      byteCounter <= (m-1 downto 0 => '0');
			elsif set = '1' then -- Set = '1' => Initialize the registers for next job
				LMode <= LModeIn;
				FSrcAdr <= FSrcIn;
				byteCounter <= countInIncr;
			else -- Set = '0' => Registers remain with same value, except byteCounter that may decrement
				byteCounter <= nextCount;
			end if;
		else
			-- Nothing
		end if;
	end process;
	
	
end arch;



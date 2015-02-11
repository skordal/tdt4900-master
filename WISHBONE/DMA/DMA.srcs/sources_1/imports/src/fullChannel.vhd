library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity fullChannel is
	generic(
		n: integer := 32;
		m: integer := 32
	);
	
	-- Combines both load and store channel
	port (
		-- Clock
		clk : in std_logic;
		reset : in std_logic;
		-- Input from DMA Main Controller
		set : in std_logic; -- Activates setting counter, final load address, final store address (and mode)
		LModeIn : in std_logic; -- Input used to set counter behaviour (fixed address vs. changing address. Will always be '1' for this project)
		SModeIn : in std_logic;
		FLAIn: in std_logic_vector(n-1 downto 0); -- Input data to FLA
		FSAIn: in std_logic_vector(n-1 downto 0); -- Input data to FSA
		countIn: in std_logic_vector(m-1 downto 0); -- Input data to counter
		decrementIn: in std_logic_vector(2 downto 0);
		
		-- Input from shared data buffer
		dataRdy : in std_logic; -- When data in shared data buffer belongs to this channel (identified by the load address)
		
		-- Input from arbiter
		loadAck : in std_logic;  
		storeAck : in std_logic; 
		
		-- Output to DMA MAin Controller
		active : out std_logic;
		
		-- Output to shared data buffer
		loadIDOut : out std_logic_vector(n-1 downto 0); -- To compare with shared data buffer
		
		-- Output to arbiter
		loadAdrOut : out std_logic_vector(2+(n-1) downto 0); -- Current load address for load request
		storeAdrOut : out std_logic_vector(2+(n-1) downto 0); -- Current store address for store request
		loadReq : out std_logic;
		storeReq : out std_logic; -- Request signal to arbiter to pass through store address to arbiter (will be passed together with data from shared buffer)
		
		-- MASTER: Output for addressing mode, needed for WB interface
        AMOut: out std_logic
		);
end fullChannel;

architecture arch of fullChannel is
	
	-- Internal signals
	signal loadActive : std_logic := '0';
	signal storeActive : std_logic := '0';
	
	--MASTER
	signal AMOut0 : std_logic := '0';
	signal AMOut1 : std_logic := '0';
	
	-- Used components:
	component loadChannel
	port(
		--INPUT
		clk : in std_logic;
		reset : in std_logic;
		
		set : in std_logic;
		LModeIn : in std_logic; 
		FLAIn: in std_logic_vector(n-1 downto 0); 
		countIn: in std_logic_vector(m-1 downto 0); 
		decrementIn: in std_logic_vector(2 downto 0);
	
		loadAck : in std_logic; 
	
		-- OUTPUT
		loadActive : out std_logic;
	
		loadAdrOut : out std_logic_vector(2+(n-1) downto 0); 
		loadReq : out std_logic;
		AMOut : out std_logic
	);
	end component;
	
	component storeChannel
	port(
		-- INPUT
		clk : in std_logic;
		reset : in std_logic;
	
		set : in std_logic;
		LModeIn : in std_logic; 
		SModeIn : in std_logic; 
		FLAIn: in std_logic_vector(n-1 downto 0); 
		FSAIn: in std_logic_vector(n-1 downto 0); 
		countIn: in std_logic_vector(m-1 downto 0); 
		decrementIn : in std_logic_vector(2 downto 0);
	
		dataRdy : in std_logic; 
	
		storeAck : in std_logic; 
	
		-- OUTPUT
		storeActive : out std_logic; 
	
		loadAdrOut : out std_logic_vector((n-1) downto 0); 
	
		storeAdrOut : out std_logic_vector(2+(n-1) downto 0); 
		storeReq : out std_logic;
        AMOut : out std_logic 
	);
	end component;
begin
	active <= loadActive OR storeActive; 
	
	loader : loadChannel
	port map(
		clk => clk,
		reset => reset,
		set => set,
		LModeIn => LModeIn,
		FLAIn => FLAIn,
		countIn => countIn,
		loadAck => loadAck,
		decrementIn => decrementIn,
		
		loadActive => loadActive,
		loadAdrOut => loadAdrOut,
		loadReq => loadReq,
		AMOut => AMOut0
	);
	
	storer : storeChannel
	port map(
		clk => clk,
		reset => reset,
		set => set,
		LModeIn => LModeIn,
		SModeIn => SModeIn,
		FLAIn => FLAIn,
		FSAIn => FSAIn,
		countIn => countIn,
		dataRdy => dataRdy,
		storeAck => storeAck,
		decrementIn => decrementIn,
		
		storeActive => storeActive,
		loadAdrOut => loadIDOut,
		storeAdrOut => storeAdrOut,
		storeReq => storeReq,
        AMOut => AMOut1        
	);
	
	-- MASTER: Easy version to set AMOut, as long as both load and store has same addressing mode
	-- (incompatible with advanced type of implementation if loading is for one job, while storing is for another, with different addressing modes) 
	AMOut <= AMOut0 OR AMOut1;
	
	-- MASTER: Advanced version to set AMOut, with possible different AMOut from load and store.
	-- If so, implement a process where AMOut is set based on if loadAck or storeAck is set
	
	
	
end arch;



library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity arbiterTop is
	generic(n: integer := 34; -- 2 bits used for receivers (after arbiter) to discern between loads, stores and interrupts, and subsequent data used as addresses or interrupt details
			m: integer := 32; -- 32 bits data
			o: integer := 3
	);
	port(
	 	-- INPUTS
	 	-- Input used by arbiter controller: 
	 	clk : in STD_LOGIC;
	 	
		blockReq : in std_logic;
		interruptReq : in std_logic;
		storeReq0: in std_logic;
		storeReq1: in std_logic;
		loadReq0: in std_logic;
		loadReq1: in std_logic;
		
		-- Inputs used by dataMux
		data_in : in STD_LOGIC_VECTOR(m-1 downto 0);
		
		-- Inputs used by adrMux
		interruptInput : in std_logic_vector(n-1 downto 0);
		storeInput0: in std_logic_vector(n-1 downto 0);
		storeInput1: in std_logic_vector(n-1 downto 0);
		loadInput0: in std_logic_vector(n-1 downto 0);
		loadInput1: in std_logic_vector(n-1 downto 0);
		
		--OUTPUTS
		-- Ack outputs to requestors
		interruptAck : out std_logic;
		storeAck0 : out std_logic;
		storeAck1 : out std_logic;
		loadAck0 : out std_logic;
		loadAck1 : out std_logic;
		
		-- Outputs that are granted access
		adrOut : out std_logic_vector(n-1 downto 0);
		dataOut : out std_logic_vector(m-1 downto 0)
		
		);
end arbiterTop;

architecture top of arbiterTop is
	--signal adrOpt : std_logic_vector(2 downto 0); 
	signal adrOpt : std_logic_vector(o-1 downto 0); 
	signal dataOpt: std_logic;
	--signal noDataOutput : std_logic_vector(31 downto 0) := "00000000000000000000000000000000"; -- Used when not store
	signal noDataOutput : std_logic_vector(m-1 downto 0) := (m-1 downto 0 => '0'); 

	component arbiterController
	port(
		clk : in std_logic;
	
		blockReq : in std_logic;
		interruptReq : in std_logic;
		storeReq0: in std_logic;
		storeReq1: in std_logic;
		loadReq0: in std_logic;
		loadReq1: in std_logic;
	
		interruptAck : out std_logic;
		storeAck0 : out std_logic;
		storeAck1 : out std_logic;
		loadAck0 : out std_logic;
		loadAck1 : out std_logic;
	
	-- Control signals to arbiter dataMux and adrMux
		dataOpt : out std_logic;
		adrOpt : out std_logic_vector(o-1 downto 0)	
		-- adrOpt : out std_logic_vector(2 downto 0)	
		);
	end component;

	component adrMux
	port(
		opt: in std_logic_vector(o-1 downto 0);
		interruptInput: in std_logic_vector(n-1 downto 0);
		storeInput0: in std_logic_vector(n-1 downto 0);
		storeInput1: in std_logic_vector(n-1 downto 0);
		loadInput0: in std_logic_vector(n-1 downto 0);
		loadInput1: in std_logic_vector(n-1 downto 0);
	
		adrOutput : out std_logic_vector(n-1 downto 0)
		
		--opt: in std_logic_vector(2 downto 0);
		--interruptInput: out std_logic_vector(33 downto 0);
		--storeInput0: in std_logic_vector(33 downto 0);
		--storeInput1: in std_logic_vector(33 downto 0);
		--loadInput0: in std_logic_vector(33 downto 0);
		--loadInput1: in std_logic_vector(33 downto 0)
		
		--adrOutput : out std_logic_vector(33 downto 0)
	);
	end component;
	
	component dataMux
	port(
		opt: in std_logic;
		dataInput0: in std_logic_vector(m-1 downto 0);
		dataInput1: in std_logic_vector(m-1 downto 0);
		
		dataOut: out std_logic_vector(m-1 downto 0)
		--dataInput0: in std_logic_vector(31 downto 0);
		--dataInput1: in std_logic_vector(31 downto 0);
		
		--dataOut: out std_logic_vector(31 downto 0)
	);
	end component;

begin
	controller : arbiterController 
	port map(
		clk => clk,
		blockReq => blockReq,
		interruptReq => interruptReq,
		storeReq0 => storeReq0,
		storeReq1 => storeReq1,
		loadReq0 => loadReq0,
		loadReq1 => loadReq1,
	
		interruptAck => interruptAck,
		storeAck0 => storeAck0,
		storeAck1 => storeAck1,
		loadAck0 => loadAck0,
		loadAck1 => loadAck1,
	
		dataOpt => dataOpt,
		adrOpt => adrOpt
	);	
	
	aMux : adrMux
	port map(
		opt => adrOpt,
		interruptInput => interruptInput,
		storeInput0 => storeInput0,
		storeInput1 => storeInput1,
		loadInput0 => loadInput0,
		loadInput1 => loadInput1,
		
		adrOutput => adrOut
	);
	
	dMux : dataMux
	port map(
		opt => dataOpt,
		dataInput0 => noDataOutput,
		dataInput1 => data_in,
		
		dataOut => dataOut
	);


end top;
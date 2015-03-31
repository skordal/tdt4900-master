library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity fullChannel is
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
end fullChannel;

architecture arch of fullChannel is
	
	-- Internal signals
	signal loadActive : std_logic := '0';
	signal storeActive : std_logic := '0';
	
	signal firstCountOut : std_logic := '0';
	signal finalCountOut : std_logic := '0';
	signal twistOut : std_logic := '0';
	
	
	-- Used components:
	component channelLoader
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
	end component;
	
	component channelStorer
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
	end component;
begin
	active <= loadActive OR storeActive; 
	storeFlagsOut <= firstCountOut & finalCountOut & twistOut;
	
	loader : channelLoader
	port map(
              clk => clk,
              reset => reset,
              
              set => set,
              LModeIn => LModeIn,
              FSrcIn => FSrcIn, 
              byteCountIn => byteCountIn,
              
              loadAck => loadAck,
              
              loadActive => loadActive,
              
              srcOut => srcOut,
              loadReq => loadReq
	);
	
	storer : channelStorer
	port map(
	            clk => clk,
                reset => reset,
                
                set => set,
                LModeIn => LModeIn,
                SModeIn => SModeIn,
                FSrcIn => FSrcIn,
                FDestIn => FDestIn,
                byteCountIn => byteCountIn,
                twistIn => twistIn,
                
                dataRdy => dataRdy,
 
                storeAck => storeAck,
            
                storeActive => storeActive,
                
                srcIDOut => srcIDOut,
                
                destOut => destOut,
                storeReq => storeReq,
                firstCountOut => firstCountOut,
                finalCountOut => finalCountOut,
                twistOut => twistOut
	);
	
	
	
end arch;



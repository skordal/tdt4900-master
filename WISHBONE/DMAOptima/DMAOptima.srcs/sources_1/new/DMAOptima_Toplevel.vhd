library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity DMAOptima_TopLevel is
	generic( n : integer := 32; -- 32-bit addresses
	         m : integer := 32;
			 u : integer := 96;	-- ReqDetails, 32 bit set as standard
			 p : integer := 64;
			 b : integer := 3;
			 k : integer := 2;
			 bufferDepth : integer := 8
	);
	
	port(
	   -- General inputs
	   clk : in std_logic;
	   reset : in std_logic;
	   
	   -- Transfer Input
	   transferDetails0 : in std_logic_vector(u-1 downto 0);
	   transferDetails1 : in std_logic_vector(u-1 downto 0);
	   
	   activateC0 : in std_logic;
	   activateC1 : in std_logic;
	   
	   -- Input from WB_MASTER to channels
	   blockTransfer : in std_logic;
	   dataIn : in std_logic_vector(p-1 downto 0);
	   storeData : in std_logic;
	   
	   -- Output from data fifo buffer
	   dataFull : out std_logic;
	   
	   -- Output from DMA to WB_MASTER
	   storeOutput : out std_logic;
	   commandOut : out std_logic_vector((n+2)-1 downto 0);
	   dataOut : out std_logic_vector(n-1 downto 0);
	   flagsOut : out std_logic_vector(2 downto 0)
	   
	   -- Output from Monitors
	   --monitorOut0 : out std_logic;
	   --monitorOut1 : out std_logic
	   
	   );
end DMAOptima_TopLevel;

architecture arch of DMAOptima_TopLevel is


    -- Connection signals
    signal Fsrc0 : std_logic_vector(31 downto 0) := (31 downto 0 => '0');
    signal Fsrc1 : std_logic_vector(31 downto 0) := (31 downto 0 => '0');
    signal Fdest0 : std_logic_vector(31 downto 0) := (31 downto 0 => '0');
    signal Fdest1: std_logic_vector(31 downto 0) := (31 downto 0 => '0');
    signal byteCount0 : std_logic_vector(31 downto 0) := (31 downto 0 => '0');
    signal byteCount1 : std_logic_vector(31 downto 0) := (31 downto 0 => '0');
    signal twist0 : std_logic := '0';
    signal twist1 : std_logic := '1';
    
    signal commandOut_internal : std_logic_vector((n+2)+b-1 downto 0) := ((n+2)+b-1 downto 0 => '0');
    signal twistedData : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');
    signal preTwistedData : std_logic_vector(n-1 downto 0 ) := (n-1 downto 0 => '0');

	
	component DetailsConverter
	port(
	           src : in STD_LOGIC_VECTOR (31 downto 0);
               dest : in STD_LOGIC_VECTOR (31 downto 0);
               details : in STD_LOGIC_VECTOR (31 downto 0);
               enable : in STD_LOGIC;
               Fsrc : out STD_LOGIC_VECTOR (31 downto 0); -- F = Final
               Fdest : out STD_LOGIC_VECTOR (31 downto 0); -- F = Final
               byteCount : out STD_LOGIC_VECTOR (31 downto 0);
               enableEndianTwist : out STD_LOGIC
	);
	end component;
	
	component ChannelMonitor
	port(
	           clk : in std_logic;
               reset : in std_logic;
                
               channelActive : in STD_LOGIC;
               interruptOut : out STD_LOGIC
               );
	end component;
	
	component EndianByteTwister
	Port ( enable : in STD_LOGIC;
               dataIn : in STD_LOGIC_VECTOR (31 downto 0);
               dataOut : out STD_LOGIC_VECTOR (31 downto 0)
    );
	end component;
	
	-- TODO: Use when optimalizing for 128 bits
	--entity EndianFWTwister is
   --     Port ( enable : in STD_LOGIC;
   --            dataIn : in STD_LOGIC_VECTOR (127 downto 0);
   --            dataOut : out STD_LOGIC_VECTOR (127 downto 0));
   -- end EndianFWTwister;
	
	component twoChannelSetUpBufferedOptima
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
            detailsOutput : out std_logic_vector(i+b-1 downto 0); -- Interrupt details, store cmd + address, or load cmd + address
            dataOutput : out std_logic_vector(n-1 downto 0);    -- Data for store cmd, or just 0's
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
	end component;
	
begin 
	
	commandOut <= commandOut_internal((n+2)+b-1 downto b);
	flagsOut(2 downto 1) <= commandOut_internal(b-1 downto 1);
	
    duoChannelWithArbiter : twoChannelSetUpBufferedOptima
    port map(
               clk => clk,
               reset => reset,
               
               set0 => activateC0,
               set1 => activateC1,
               LModeIn0 => '1',
               LModeIn1 => '1',
               SModeIn0 => '1',
               SModeIn1 => '1',
               FSrcIn0 => FSrc0,
               FSrcIn1 => FSrc1,
               FDestIn0 => FDest0,
               FDestIn1 => FDest1,
               byteCountIn0 => byteCount0,
               byteCountIn1 => byteCount1,
               twistIn0 => twist0,
               twistIn1 => twist1,
               
               srcIDIn => dataIn(63 downto 32), 
               dataIn => dataIn(31 downto 0),
               pushData => storeData,
               
               blockArbiter => blockTransfer, 
               
               detailsOutput => commandOut_internal,
               dataOutput => preTwistedData,
               IDOut => flagsOut(0),
               
               storeOutput => storeOutput,
               
               --active0 =>
               --active1 =>
               
               bufferFull =>dataFull   
    );  
    
    converter0 : DetailsConverter
    port map(
        src => transferDetails0(95 downto 64),
        dest => transferDetails0(63 downto 32),
        details => transferDetails0(31 downto 0),
        enable => activateC0,
        Fsrc => Fsrc0,
        Fdest => Fdest0,
        byteCount => byteCount0,
        enableEndianTwist => twist0
    );
    
    converter1 : DetailsConverter
        port map(
            src => transferDetails1(95 downto 64),
            dest => transferDetails1(63 downto 32),
            details => transferDetails1(31 downto 0),
            enable => activateC1,
            Fsrc => Fsrc1,
            Fdest => Fdest1,
            byteCount => byteCount1,
            enableEndianTwist => twist1
        );
      
      
     twister : EndianByteTwister
     port map(
        enable => commandOut_internal(0),
        dataIn => preTwistedData,
        dataOut => twistedData
     ); 
      
      dataOut <= twistedData;
      
     -- TODO: Use when swicthing over to 128 bits       
    --twister : EndianFWTwister
    --port map(
    --        enable => commandOut_internal(0),
    --        
    --        dataIn => preTwistedData,
    --        dataOut => twistedData
    --);
    
    
	
end arch;












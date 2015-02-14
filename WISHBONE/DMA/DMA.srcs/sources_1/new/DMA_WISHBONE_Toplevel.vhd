----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/02/2015 05:42:11 PM
-- Design Name: 
-- Module Name: DMA_WISHBONE_Toplevel - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DMA_WISHBONE_Toplevel is
    Port ( 
    
            -- WISHBONE COMMON INPUTS 
               clk_i : in STD_LOGIC;
              rst_i : in STD_LOGIC;
              dat_i : in STD_LOGIC_VECTOR (127 downto 0);
              tgd_i : in STD_LOGIC_VECTOR (2 downto 0);
              
            -- WISHBONE MASTER INPUTS   
              ack_i : in STD_LOGIC;
              err_i : in STD_LOGIC;
              rty_i : in STD_LOGIC;
              stall_i: in STD_LOGIC;
              
              -- WISHBONE MASTER OUTPUTS
              M_dat_o : out STD_LOGIC_VECTOR (127 downto 0);
              M_tgd_o : out STD_LOGIC_VECTOR (2 downto 0);
              adr_o : out STD_LOGIC_VECTOR (31 downto 0);
              cyc_o : out STD_LOGIC;
              lock_o : out STD_LOGIC;
              sel_o : out STD_LOGIC_VECTOR (1 downto 0);
              stb_o : out STD_LOGIC;
              tga_o : out STD_LOGIC_VECTOR (2 downto 0);
              tgc_o : out STD_LOGIC_VECTOR (2 downto 0);
              we_o : out STD_LOGIC;
    
             -- WISHBONE SLAVE INPUTS 
             adr_i : in STD_LOGIC_VECTOR (31 downto 0);
             cyc_i : in STD_LOGIC;
             lock_i : in std_logic;
             sel_i : in std_logic;
             stb_i : in std_logic;
             tga_i : in std_logic;
             tgc_i : in std_logic;
             we_i : in std_logic;
           
             -- WISHBONE SLAVE OUTPUTS
             S_dat_o : out STD_LOGIC_VECTOR (127 downto 0);
             S_tgd_o : out STD_LOGIC_VECTOR (2 downto 0);             
             ack_o : out std_logic;
             err_o : out std_logic;
             rty_o : out std_logic;
             stall_o : out std_logic;
    
    
--           -- DMA slave inputs
--            SRegIn : in STD_LOGIC_VECTOR (31 downto 0);
--            LRegIn : in STD_LOGIC_VECTOR (31 downto 0);
--            RRegIn : in STD_LOGIC_VECTOR (31 downto 0);
--            writeRReg : in STD_LOGIC;
--            -- DMA slave outputs
--            RRegOut : out STD_LOGIC_VECTOR (31 downto 0);

            -- IRC
            interrupt : out std_logic
    );
    
           
end DMA_WISHBONE_Toplevel;

architecture Behavioral of DMA_WISHBONE_Toplevel is
    -- Internal signals
    
--    signal interrupt_signal : std_logic := '0';
--    signal clear : std_logic := '0'; -- Signal used to clear RReg when DMA has completed
    
    -- Interim signals, DMA -> Wishbone interface
    signal newDMAOutputToWB :  STD_LOGIC := '0';                          
    signal DMADetailsToWB :  STD_LOGIC_VECTOR (33 downto 0) := (33 downto 0 => '0');   
    signal DMADataOutToWB :  STD_LOGIC_VECTOR (31 downto 0) := (31 downto 0 => '0');       
    signal DMAAMOutToWB : STD_LOGIC := '0';
    
    -- Interim signals, Wishbone interface -> DMA                                                      
    signal blockNewOutputToDMA : STD_LOGIC := '0';
    signal newDMAInputToDMA : STD_LOGIC := '0';                          
    signal DMAAddressInToDMA : STD_LOGIC_VECTOR (31 downto 0) := (31 downto 0 => '0');    
    signal DMADataInToDMA : STD_LOGIC_VECTOR (31 downto 0) := (31 downto 0 => '0');       
      
    -- Signal for concatination
    signal DMADataInTotal : STD_LOGIC_VECTOR(63 downto 0) := (63 downto 0 => '0');
    
    
--    -- Internal registers for setting up DMA:
    
--    signal SReg : STD_LOGIC_VECTOR (31 downto 0) := (31 downto 0 => '0'); -- Start Storing Address
--    signal LReg : STD_LOGIC_VECTOR (31 downto 0) := (31 downto 0 => '0'); -- Start Loading Address
--    -- Use of Request details register: 
--    -- 31-20: Count, number of individual transactions. 19: Bit or Byte addressing, 18-12: RequestID
--    -- 10-1: NOT IN USE, 0: ON/OFF
--    signal RReg : STD_LOGIC_VECTOR (31 downto 0) := (31 downto 0 => '0'); -- Request details. 
--    signal RRegPrev : STD_LOGIC := '0'; -- Used to compare RReg for each previous cycle. If RReg(0) = '1' and RRegPrev = '0', a new request has been written to register
    
    
    
    
    
    
    -- Signals from WB_Slave to DMA, and WB_MASTER to DMA
    signal activateDMA : std_logic := '0';
    signal DMARequestInput : std_logic_vector (95 downto 0) := (95 downto 0 => '0'); 
    signal interrupt_signal : std_logic := '0';
    
    -- System Register used to recognize new request
    signal previousOnOff : std_logic := '0';
    
    -- Components

     component DMAToplevel -- The DMA Module itself
	   generic( n : integer := 32; 
             m : integer := 32;
             u : integer := 96;    
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
	end component;
	
	component WISHBONE_DMA_MASTER_STANDARD_SC
	Port (
                    -- WISHBONE MASTER INPUTS
                    clk_i : in STD_LOGIC;
                     rst_i : in STD_LOGIC;
                     dat_i : in STD_LOGIC_VECTOR (127 downto 0);
                     ack_i : in STD_LOGIC;
                     err_i : in STD_LOGIC;
                     rty_i : in STD_LOGIC;
                     tgd_i : in STD_LOGIC_VECTOR (2 downto 0);
                     
                     -- WISHBONE MASTER OUTPUTS
                     adr_o : out STD_LOGIC_VECTOR (31 downto 0);
                     dat_o : out STD_LOGIC_VECTOR (127 downto 0);
                     cyc_o : out STD_LOGIC;
                     lock_o : out STD_LOGIC;
                     sel_o : out STD_LOGIC_VECTOR (1 downto 0);
                     stb_o : out STD_LOGIC;
                     tga_o : out STD_LOGIC_VECTOR (2 downto 0);
                     tgc_o : out STD_LOGIC_VECTOR (2 downto 0);
                     tgd_o : out STD_LOGIC_VECTOR (2 downto 0);
                     we_o : out STD_LOGIC;
        
                    -- Inputs from DMA
                    newDMAOutput : in STD_LOGIC;
                    DMADetailsOut : in  STD_LOGIC_VECTOR (33 downto 0);
                    DMADataOut : in STD_LOGIC_VECTOR (31 downto 0);
                    DMAAMOut : in std_logic;
                    
                    -- Outputs to DMA
                    blockNewOutput : out STD_LOGIC; 
                    newDMAInput : out STD_LOGIC;
                    DMAAddressIn : out STD_LOGIC_VECTOR (31 downto 0);
                    DMADAtaIn : out STD_LOGIC_VECTOR (31 downto 0);
                    
                    -- Outputs to Slave Registers
                    clear : out STD_LOGIC
     );
     end component;
     
     component WISHBONE_DMA_SLAVE
         Port (
           -- WISHBONE COMMON INPUTS 
              clk_i : in STD_LOGIC;
              rst_i : in STD_LOGIC;
              dat_i : in STD_LOGIC_VECTOR (127 downto 0);
              dat_o : out STD_LOGIC_VECTOR (127 downto 0);
              tgd_i : in STD_LOGIC_VECTOR (2 downto 0);
             tgd_o : out STD_LOGIC_VECTOR (2 downto 0);
             
               -- WISHBONE SLAVE INPUTS                         
               adr_i : in STD_LOGIC_VECTOR (31 downto 0);       
               cyc_i : in STD_LOGIC;                            
               lock_i : in std_logic;                           
               sel_i : in std_logic;                            
               stb_i : in std_logic;                            
               tga_i : in std_logic;                            
               tgc_i : in std_logic;                            
               we_i : in std_logic;                             
                                                                
               -- WISHBONE SLAVE OUTPUTS                        
               ack_o : out std_logic;                           
               err_o : out std_logic;                           
               rty_o : out std_logic;                           
               stall_o : out std_logic;
               
               -- Inputs to DMA (1 channel only)
               requestDetails : out std_logic_vector(95 downto 0);
               activate : out std_logic;
               
               -- Outputs from WB_Master (DMA)
               clear : in std_logic          
          );
          end component;
     
begin

    DMA : DMAToplevel
    port map(
        clk => clk_i,
        reset => rst_i,
        
        reqIn => DMARequestInput,
        reqStore => activateDMA,
        
        dataIn => DMADataInTotal,
        dataStore => newDMAInputToDMA,
        
        outputFull => blockNewOutputToDMA,
        
        -- reqFull => -- Not useful for current implementation, since outer design will have only one instance at the time
        -- dataFull => -- Not useful for current implementation, since outer design will have only one instance at the time
    
        storeOutput => newDMAOutputToWB,
        detailsOut => DMADetailsToWB,
        dataOut => DMADataOutToWB,
        AMOut => DMAAMOutToWB
    );
    
    WISHBONE_DMA_MASTER : WISHBONE_DMA_MASTER_STANDARD_SC
    port map(
        -- WBM Inputs
        clk_i => clk_i,
        rst_i => rst_i,
        dat_i => dat_i, 
        ack_i => ack_i, 
        err_i => err_i, 
        rty_i => rty_i, 
        tgd_i => tgd_i, 
        
        -- WBM Outputs         
        adr_o => adr_o, 
        dat_o => M_dat_o, 
        cyc_o => cyc_o, 
        lock_o => lock_o,
        sel_o => sel_o,
        stb_o => stb_o, 
        tga_o => tga_o,
        tgc_o => tgc_o,
        tgd_o => M_tgd_o,
        we_o => we_o,
        
        -- Inputs from DMA
        newDMAOutput => newDMAOutputToWB,
        DMADetailsOut => DMADetailsToWB,
        DMADataOut => DMADataOutToWB,
        DMAAMOut => DMAAMOutToWB,
                       
        -- Outputs to DMA
        blockNewOutput => blockNewOutputToDMA,
        newDMAInput => newDMAInputToDMA,
        DMAAddressIn => DMAAddressInToDMA,
        DMADAtaIn =>DMADataInToDMA,
                       
        -- Outputs to RReg
        clear => interrupt_signal
        
    );
    
    WISHBONE_DMA_SLAVE0 : WISHBONE_DMA_SLAVE
    port map(
          -- WBS Inputs
         clk_i => clk_i,
         rst_i => rst_i,
         dat_i => dat_i,
         tgd_i => tgd_i,
    
         adr_i => adr_i,  
         cyc_i => cyc_i,
         lock_i => lock_i,
         sel_i => sel_i,
         stb_i => stb_i,
         tga_i => tga_i,
         tgc_i => tgc_i,
         we_i => we_i,
    
         -- WBS Outputs
  
        dat_o => S_dat_o,
        tgd_o => S_tgd_o,        
        ack_o => ack_o,
        err_o => err_o,
        rty_o => rty_o,
        stall_o => stall_o,
        
        -- Input from WBM
        clear => interrupt_signal,
    
        -- Output to DMA
        requestDetails => DMARequestInput,
        activate => activateDMA    
    
    
    
    
    );

    -- Combinatoric signals
    DMADataInTotal <= DMAAddressInToDMA & DMADAtaInToDMA;
    interrupt <= interrupt_signal;
    
    
    
    -- Behaviour signals and processes
--    updateRegisterAndActivateDMA : Process (clk_i, rst_i, DMARequestInput, previousOnOff)
--    begin
--        if rising_edge(clk_i) then
--            if rst_i = '1' then
--                previousOnOff <= '0';
--                activateDMA <= '0';
--            else
--                previousOnOff <= DMARequestInput(0);
--                if DMARequestInput(0) = '1' and previousOnOff = '0' then
--                    activateDMA <= '1'; -- The moment the ON/OFF bit is set to on in Slave, the activateDMA-signal should be high to activate coming from slave to the DMA Module
--                else
--                    activateDMA <= '0';
--                end if
--            end if;    
--        end if;
--    end process;
    
        
--    updateRegisters : process (clk_i, rst_i, writeRreg, SRegIn, LRegIn, RRegIn, clear)
--    begin
--        if rising_edge(clk_i) then
--            if rst_i = '1' then
--                SReg <= (31 downto 0 => '0');
--                LReg <= (31 downto 0 => '0');
--                RReg <= (31 downto 0 => '0');
--                interrupt <= '0';
--            elsif writeRreg = '1' then
--                SReg <= SRegIn;
--                LReg <= LRegIn;
--                RReg <= RRegIn;
--                interrupt <= '0';
--            elsif clear = '1' then
--                interrupt <= '1';
--                Rreg(0) <= '0';
--            else
--                interrupt <= '0';
--            end if;
--        end if;
--    end process;


end Behavioral;

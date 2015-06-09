----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/11/2015 10:49:48 PM
-- Design Name: 
-- Module Name: WISHBONE_DMA_SLAVE - Behavioral
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
--use common_defs.v;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity WISHBONE_DMA_SLAVE is
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
      sel_i : in std_logic_vector(15 downto 0);                           
      stb_i : in std_logic;                           
      tga_i : in std_logic;                           
      tgc_i : in std_logic;                           
      we_i : in std_logic;                            
                                                      
      -- WISHBONE SLAVE OUTPUTS                       
      ack_o : out std_logic;                          
      err_o : out std_logic;                          
      rty_o : out std_logic;                          
      stall_o : out std_logic;
      interrupt : out std_logic;
      
       -- Inputs to DMA (1 channel only)              
      transferDetails0 : out std_logic_vector(95 downto 0);
      transferDetails1 : out std_logic_vector(95 downto 0);    
      activate0 : out std_logic;
      activate1 : out std_logic;                      
                                                     
      -- Outputs from WB_Master (DMA)                
      clear0 : in std_logic;
      clear1 : in std_logic                                                    
 );                           
end WISHBONE_DMA_SLAVE;

architecture Behavioral of WISHBONE_DMA_SLAVE is
    
    -- Channel 0 register
    signal LReg0 : std_logic_vector(31 downto 0) := (31 downto 0 => '0'); -- Loading Register
    signal SReg0 : std_logic_vector(31 downto 0) := (31 downto 0 => '0'); -- Storing Register
    signal RReg0 : std_logic_vector(31 downto 0) := (31 downto 0 => '0'); -- Request Register: Count (31-20), Job Finished (interrupt) (2), Twist Endian bytes in words(1), ON/OFF (0)
    
    -- Channel 1 register
    signal LReg1 : std_logic_vector(31 downto 0) := (31 downto 0 => '0'); -- Loading Register
    signal SReg1 : std_logic_vector(31 downto 0) := (31 downto 0 => '0'); --
    signal RReg1 : std_logic_vector(31 downto 0) := (31 downto 0 => '0'); -- Request Register: Count (31-20), Job Finished (interrupt) (2),  Twist Endian bytes in words(1), ON/OFF (0)
        
    
    
    -- Flip-flop for setting the DMA-activate signal at correct moments
    signal previousOnOff0 : std_logic := '0';
    signal previousOnOff1 : std_logic := '0';
        
    
    -- Signals, for logical expressions
    signal wb_start_read : std_logic := '0';
    signal wb_start_read_d1 : std_logic := '0';
    signal wb_start_write : std_logic := '0'; 
    
    -- Wires and internal signals
    signal readData32 : std_logic_vector(31 downto 0) := (31 downto 0 => '0');
    signal writeData32 : std_logic_vector(31 downto 0) := (31 downto 0 => '0');
    signal ack_o_signal : std_logic := '0';


begin

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------   MODULE BEHAVIOR TOWARDS DMA   ---------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    -- Output not in use
    tgd_o <= "000";
    err_o <= '0';
    rty_o <= '0';
    stall_o <= '0';

    -- Processes for acticating channels 0 and 1
    activateChannel0 : Process (clk_i, rst_i, RReg0, previousOnOff0)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                previousOnOff0 <= '0';
                activate0 <= '0';
            else
                previousOnOff0 <= RReg0(0);
                if RReg0(0) = '1' and previousOnOff0 = '0' then
                    activate0 <= '1'; -- Setting ON recognized, activate channel 0
                else
                    activate0 <= '0';
                end if;
            end if;    
        end if;
    end process;

    activateChannel1 : Process (clk_i, rst_i, RReg1, previousOnOff1)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                previousOnOff1 <= '0';
                activate1 <= '0';
            else
                previousOnOff1 <= RReg1(0);
                if RReg1(0) = '1' and previousOnOff1 = '0' then
                    activate1 <= '1'; -- Setting ON recognized, activate channel 1
                else
                    activate1 <= '0';
                end if;
            end if;    
        end if;
    end process;

    transferDetails0 <= LReg0 & SReg0 & RReg0;
    transferDetails1 <= LReg1 & SReg1 & RReg1;

    ack_o_signal <= stb_i AND (wb_start_write OR wb_start_read_d1);-- AND NOT (clear0 OR clear1);
    ack_o <= ack_o_signal;
    
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------       REGISTER READ/WRITE       ---------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Read register

    wb_start_read  <= stb_i AND NOT we_i AND NOT ack_o_signal;
    
    -- To avoid having writes and reads overlap each other
    setRead_d1 : process (clk_i, rst_i, wb_start_read)
    begin
        if rst_i = '1' then
            wb_start_read_d1 <= '0'; --TODO: Warning, check if it really is asynchronous in other interfaces
        elsif rising_edge(clk_i) then
            wb_start_read_d1 <= wb_start_read;
        end if;
    end process; 

    
    readRegister : process (clk_i, rst_i, wb_start_read, adr_i, LReg0, SReg0, RReg0, LReg1, SReg1, RReg1)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
            
            elsif wb_start_read = '1' then
                case adr_i(11 downto 0) is
                    --WHEN TILEREG_DMA_LREG0 => 
                    WHEN "000000000000" =>
                        readData32 <= LReg0;
                    --WHEN TILEREG_DMA_SREG0 =>
                    WHEN "000000000100" =>
                        readData32 <= SReg0;
                    --WHEN TILEREG_DMA_RREG0 =>
                    WHEN "000000001000" =>
                        readData32 <= RReg0;
                    --WHEN TILEREG_DMA_LREG0 => 
                    WHEN "000000001100" =>
                        readData32 <= LReg1;
                    --WHEN TILEREG_DMA_SREG0 =>
                    WHEN "000000010000" =>
                        readData32 <= SReg1;
                    --WHEN TILEREG_DMA_RREG0 =>
                    WHEN "000000010100" =>
                        readData32 <= RReg1;
      
                    WHEN OTHERS =>
                        readData32 <= (31 downto 0 => '0');
                end case;
            end if;
        end if;
    end process;

    dat_o(127 downto 96) <= readData32;
    dat_o(95 downto 64) <= readData32;
    dat_o(63 downto 32) <= readData32;
    dat_o(31 downto 0) <= readData32;


-- Write register    

    wb_start_write <= stb_i AND we_i AND NOT wb_start_read_d1;


    -- Select from 128-bit input
    selectInput : process(adr_i, wb_start_write, dat_i)
    begin
        if wb_start_write = '1' then
            if adr_i(3 downto 2) = "11" then
                writeData32 <= dat_i(127 downto 96);
            elsif adr_i(3 downto 2) = "10" then
                writeData32 <= dat_i(95 downto 64);
            elsif adr_i(3 downto 2) = "01" then
                writeData32 <= dat_i(63 downto 32);
            elsif adr_i(3 downto 2) = "00" then
                writeData32 <= dat_i(31 downto 0);
            end if;
        end if;
    end process;
    
    -- 32-bit version:
    -- writeData32 <= dat_i;
    
    -- Select register to write to, perform write at clock tick
    writeRegister : process(clk_i, rst_i, clear0, clear1, wb_start_write, writeData32, adr_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then --Reset
                LReg0 <= (31 downto 0 => '0');
                SReg0 <= (31 downto 0 => '0');
                RReg0 <= (31 downto 0 => '0');
                LReg1 <= (31 downto 0 => '0');
                SReg1 <= (31 downto 0 => '0');
                RReg1 <= (31 downto 0 => '0');
            elsif wb_start_write = '1' then --Standard write to register
                case adr_i(11 downto 0) is
                    --WHEN TILEREG_DMA_LREG0 => 
                    WHEN "000000000000" =>
                        LReg0 <= writeData32;
                    --WHEN TILEREG_DMA_SREG0 =>
                    WHEN "000000000100" =>
                        SReg0 <= writeData32;
                    --WHEN TILEREG_DMA_RREG0 =>
                    WHEN "000000001000" =>
                        RReg0 <= writeData32(31 downto 3) & '0' & writeData32(1 downto 0); --Bit 2 flag for job done, set to 0 if written by system, otherwise set by DMA master
                    --WHEN TILEREG_DMA_LREG0 => 
                    WHEN "000000001100" =>
                        LReg1 <= writeData32;
                    --WHEN TILEREG_DMA_SREG0 =>
                    WHEN "000000010000" =>
                        SReg1 <= writeData32;
                    --WHEN TILEREG_DMA_RREG0 =>
                    WHEN "000000010100" =>
                        RReg1 <= writeData32(31 downto 3) & '0' & writeData32(1 downto 0); --Bit 2 flag for job done, set to 0 if written by system, otherwise set by DMA master

                    WHEN OTHERS =>
                        -- Nothing happens.
                end case;
            elsif clear0 = '1' then --Interrupt due to finished work from DMA-module. 
                RReg0(0) <= '0';
                RReg0(2) <= '1';
            elsif clear1 = '1' then
                RReg1(0) <= '0';
                RReg1(2) <= '1';
            end if;
            
        end if;
    end process;
    
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------        INTERRUPT OUTPUT         ---------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    interrupt <= RReg0(2) or RReg1(2); 
    
end Behavioral;

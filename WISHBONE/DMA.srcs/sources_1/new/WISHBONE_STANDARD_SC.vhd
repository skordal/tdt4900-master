----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/02/2015 05:45:15 PM
-- Design Name: 
-- Module Name: WISHBONE_STANDARD_SC - Behavioral
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

entity WISHBONE_STANDARD_SC is
    Port (
                -- WISHBONE MASTER INPUTS
                clk_i : in STD_LOGIC;
                 rst_i : in STD_LOGIC;
                 dat_i : in STD_LOGIC_VECTOR (31 downto 0);
                 ack_i : in STD_LOGIC;
                 err_i : in STD_LOGIC;
                 rty_i : in STD_LOGIC;
                 tgd_i : in STD_LOGIC_VECTOR (2 downto 0);
                 
                 -- WISHBONE MASTER OUTPUTS
                 adr_o : out STD_LOGIC_VECTOR (31 downto 0);
                 dat_o : out STD_LOGIC_VECTOR (31 downto 0);
                 cyc_o : out STD_LOGIC;
                 lock_o : out STD_LOGIC;
                 sel_o : out STD_LOGIC_VECTOR (31 downto 0);
                 stb_o : out STD_LOGIC;
                 tga_o : out STD_LOGIC_VECTOR (2 downto 0);
                 tgc_o : out STD_LOGIC_VECTOR (2 downto 0);
                 tgd_o : out STD_LOGIC_VECTOR (2 downto 0);
                 we_o : out STD_LOGIC;
    
                -- Inputs from DMA
                newDMAOutput : in STD_LOGIC;
                DMADetailsOut : in  STD_LOGIC_VECTOR (33 downto 0);
                DMADataOut : in STD_LOGIC_VECTOR (31 downto 0);
                
                -- Outputs to DMA
                blockNewOutput : out STD_LOGIC;
                newDMAInput : out STD_LOGIC;
                DMAAddressIn : out STD_LOGIC_VECTOR (31 downto 0);
                DMADataIn : out STD_LOGIC_VECTOR (31 downto 0);
                
                -- Outputs to Slave Registers
                clear : out STD_LOGIC
     );
end WISHBONE_STANDARD_SC;

architecture Behavioral of WISHBONE_STANDARD_SC is
    -- Internal registers, used when transfering data from DMA to system
    signal typeReg: std_logic_vector(1 downto 0) := "00"; -- 
    signal addrReg : std_logic_vector(31 downto 0) := (31 downto 0 => '0');
    signal datReg : std_logic_vector(31 downto 0) := (31 downto 0 => '0');
    signal active : std_logic := '0';
    
    -- Buffer register for incoming data, in order to synchronize with store signal to DMA Module
    signal inputDataBuffer : std_logic_vector(31 downto 0) := (31 downto 0 => '0'); 

begin

    cyc_o <= active;
    stb_o <= active; -- Works for Single Cycle. May change on more advanced implementation
    adr_o <= addrReg;
    dat_o <= datReg;
    
    DMADataIn <= inputDataBuffer; -- Connect data input directly to DMA Module
    DMAAddressIn <= addrReg; -- Use loading address register to store Load ID with assosiated data to the DMA MOdule
    blockNewOutput <= active; -- Use active signal to prevent DMA Module sending out more single transfer requests
    
    
    setWriteEnable : process(typeReg)-- Set we_o based on typeReg (01 is storing)
    begin
        if typeReg = "01" then
            we_o <= '1';
        else
            we_o <= '0';
        end if;
    end process;

    updateRegisters : process(clk_i, rst_i, ack_i, active, newDMAOutput, DMADetailsOut, DMADAtaOut, typeReg)
        variable clear_var : std_logic;
        variable DMA_var : std_logic;
    begin
        if rising_edge(clk_i) then
            clear_var := '0';
            DMA_var := '0';
            if rst_i = '1' then -- Reset
                typeReg <= "00";
                addrReg <= (31 downto 0 => '0');
                datReg <= (31 downto 0 => '0');
                inputDataBuffer <= (31 downto 0 => '0');
                active <= '0';
            elsif active = '1' then -- Interface occupied with current transfer
                if ack_i = '1' then -- Acknowledged
                    active <= '0';
                    if typeReg = "00" then -- Load. Latch from data input to DMA by making the DMA store data input.
                        DMA_var := '1';
                        inputDataBuffer <= dat_i;
                    end if;
                else
                    active <= '1'; -- Keep occupied until acknowledged
                end if;
            elsif newDMAOutput = '1' then -- Ready for next
                if DMADetailsOut(33 downto 32) = "11" then -- Interrupt
                    clear_var := '1';
                    active <= '0';
                elsif DMADetailsOut(33) = '0' then -- Load or store
                    typeReg <= DMADetailsOut(33 downto 32);
                    addrReg <= DMADetailsOut(31 downto 0);
                    datReg <= DMADataOut;
                    active <= '1';
                end if;
            end if;
            clear <= clear_var;
            newDMAInput <= DMA_var;
        end if;
    end process;

end Behavioral;

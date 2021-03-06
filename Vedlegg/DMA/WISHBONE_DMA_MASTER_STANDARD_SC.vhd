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

entity WISHBONE_DMA_MASTER_STANDARD_SC is
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
                 sel_o : out STD_LOGIC_VECTOR (15 downto 0);
                 stb_o : out STD_LOGIC;
                 tga_o : out STD_LOGIC_VECTOR (2 downto 0);
                 tgc_o : out STD_LOGIC_VECTOR (2 downto 0);
                 tgd_o : out STD_LOGIC_VECTOR (2 downto 0);
                 we_o : out STD_LOGIC;
    
                -- Inputs from DMA
                newDMAOutput : in STD_LOGIC;
                DMADetailsOut : in  STD_LOGIC_VECTOR (33 downto 0);
                DMADataOut : in STD_LOGIC_VECTOR (31 downto 0);
                DMAFlagsOut : in std_logic_vector(2 downto 0);
                
                -- Outputs to DMA
                blockNewOutput : out STD_LOGIC;
                newDMAInput : out STD_LOGIC;
                DMAAddressIn : out STD_LOGIC_VECTOR (31 downto 0);
                DMADataIn : out STD_LOGIC_VECTOR (31 downto 0);
                
                -- Outputs to Slave Registers
                clear0 : out STD_LOGIC;
                clear1 : out std_logic
     );
end WISHBONE_DMA_MASTER_STANDARD_SC;

architecture Behavioral of WISHBONE_DMA_MASTER_STANDARD_SC is
    -- Internal registers, used when transfering data from DMA to system
    signal typeReg: std_logic_vector(1 downto 0) := "00"; -- 
    signal addrReg : std_logic_vector(31 downto 0) := (31 downto 0 => '0');
    signal datReg : std_logic_vector(31 downto 0) := (31 downto 0 => '0');
    signal active : std_logic := '0';
    
    -- Flag register
    signal firstCount : std_logic := '0';
    signal finalCount : std_logic := '0';
    signal channelID : std_logic := '0';
    
    -- Buffer register for incoming data, in order to synchronize with store signal to DMA Module
    signal inputDataBuffer : std_logic_vector(31 downto 0) := (31 downto 0 => '0'); 

    -- Internal signals
    signal sel_internal : std_logic_vector(15 downto 0) := (15 downto 0 => '0'); -- Internal version of sel_o
    signal dat_selected : std_logic_vector(31 downto 0) := (31 downto 0 => '0'); -- Selected data from dat_i based in sel_internal. Used for simplification

begin

    cyc_o <= active;
    stb_o <= active; -- Works for Single Cycle. May change on more advanced implementation
    adr_o <= addrReg;
    --dat_o <= datReg;
    sel_o <= sel_internal;
    lock_o <= '0';
    tga_o <= "000";
    tgc_o <= "000";
    tgd_o <= "000";
    
    
    
    
    DMADataIn <= inputDataBuffer; -- Connect data input directly to DMA Module
    DMAAddressIn <= addrReg; -- Use loading address register to store Load ID with assosiated data to the DMA MOdule
    blockNewOutput <= active; -- Use active signal to prevent DMA Module sending out more single transfer requests
    
    
    setWriteEnable : process(typeReg)-- Set we_o based on typeReg (01 is storing)
    begin
        if typeReg = "01" and active = '1' then
            we_o <= '1';
        else
            we_o <= '0';
        end if;
    end process;

    updateRegisters : process(clk_i, rst_i, ack_i, active, newDMAOutput, DMADetailsOut, DMADAtaOut, typeReg)
       -- variable clear_var : std_logic;
        variable DMA_var : std_logic;
    begin
        if rising_edge(clk_i) then
            --clear_var := '0';
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
                        inputDataBuffer <= dat_selected;
                    end if;
                else
                    active <= '1'; -- Keep occupied until acknowledged
                end if;
            elsif newDMAOutput = '1' then -- Ready for next
                --if DMADetailsOut(33 downto 32) = "11" then -- Interrupt
                    --clear_var := '1';
                    --active <= '0';
                --elsif DMADetailsOut(33) = '0' then -- Load or store
                if DMADetailsOut(33) = '0' then -- Load or store
                    typeReg <= DMADetailsOut(33 downto 32);
                    addrReg <= DMADetailsOut(31 downto 0);
                    datReg <= DMADataOut;
                    active <= '1';
                end if;
            end if;
            --clear <= clear_var;
            newDMAInput <= DMA_var;
        end if;
    end process;

    updateFlagRestiresAndClear : process(clk_i, rst_i, DMAFlagsOut)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                firstCount <= '0';
                finalCount <= '0';
                channelID <= '0';
            elsif active = '0' and newDMAOutput = '1' then -- Ready to load next data
                firstCount <= DMAFlagsOut(2);
                finalCount <= DMAFlagsOut(1);
                channelID <= DMAFlagsOut(0);
            end if;
        end if;
    end process;
    
    -- Send out interrupt and clear signal to correct slave ragister (RREG0 or RREG1 on behalf of channels 0 and 1, respecitebly)
    -- when final transfer (finalCount = '1') is done (ack_i = '1')
    setClear : process(clk_i, finalCount, channelID, ack_i) 
    begin
        if rising_edge(clk_i) then
            if finalCount = '1' and ack_i = '1' then
                if channelID = '0' then
                    clear0 <= '1';
                    clear1 <= '0';
                else
                    clear0 <= '0';
                    clear1 <= '1';
                end if;
            else
                clear0 <= '0';
                clear1 <= '0';
            end if;
        end if;
    end process;
    

    -- Choose which bits from address register to set sel_o (and sel_internal), based on addressing mode (byte or word)
--    setSel : process(AMReg, addrReg)
--    begin
--        if AMReg = '1' then -- Byte addressing
--            sel_internal(1 downto 0) <= addrReg (3 downto 2);
--        else  -- Word addressing
--            sel_internal(1 downto 0) <= addrReg (1 downto 0);
--        end if;
--    end process;

    -- Choose where to read from dat_i and where to write on dat_o, based on sel_internal
--    selectDatSpace : process(active, typeReg, sel_internal, dat_i, datReg)
--    variable dat_var : std_logic_vector (31 downto 0);
--    begin
--    dat_var := (31 downto 0 => '0');
--    if active = '1' then -- No point if active is low
--        if typereg = "00" then -- LOADS
--            if sel_internal = "00" then
--                dat_var := dat_i(31 downto 0);
--            elsif sel_internal = "01" then
--                dat_var := dat_i(63 downto 32);
--            elsif sel_internal = "10" then
--                dat_var := dat_i(95 downto 64);
--            else
--                dat_var := dat_i(127 downto 96);
--            end if;
        
--        elsif typereg = "01" then -- STORES
--            if sel_internal = "00" then
--                dat_o(127 downto 32) <= (127 downto 32 => '0');
--                dat_o(31 downto 0) <= datReg;
--            elsif sel_internal = "01" then
--                dat_o(127 downto 64) <= (127 downto 64 => '0');
--                dat_o(63 downto 32) <= datReg;
--                dat_o(31 downto 0) <= (31 downto 0 => '0');
--            elsif sel_internal = "10" then
--                dat_o(127 downto 96) <= (127 downto 96 => '0');
--                dat_o(95 downto 64) <= datReg;
--                dat_o(63 downto 0) <= (63 downto 0 => '0');
--            else
--                dat_o(127 downto 96) <= datReg;
--                dat_o(95 downto 0) <= (95 downto 0 => '0');
--            end if;
--        end if;
--    else
--        dat_o <= (127 downto 0 => '-'); -- Attempt at don't care, in order to avoid crash with Slave module
--    end if;
--    dat_selected <= dat_var;
--    end process;
    
   -- Version using addreReg instead of selInternal (byte addressing only)
    selectDatSpace : process(active, typeReg, addrReg, dat_i, datReg)
        variable dat_var : std_logic_vector (31 downto 0);
        variable sel_var : std_logic_vector (15 downto 0);
    begin
        dat_var := (31 downto 0 => '0');
        sel_var := (15 downto 0 => '0');
        if active = '1' then -- No point if active is low
            if typereg = "00" then -- LOADS
                if addrReg(3 downto 2) = "00" then
                    dat_var := dat_i(31 downto 0);
                    sel_var := "0000000000001111";
                elsif addrReg(3 downto 2) = "01" then
                    dat_var := dat_i(63 downto 32);
                    sel_var := "0000000011110000";
                elsif addrReg(3 downto 2) = "10" then
                    dat_var := dat_i(95 downto 64);
                    sel_var := "0000111100000000";
                else
                    dat_var := dat_i(127 downto 96);
                    sel_var := "1111000000000000";
                end if;
    
            elsif typereg = "01" then -- STORES
                if addrReg(3 downto 2) = "00" then
                    dat_o(127 downto 32) <= (127 downto 32 => '0');
                    dat_o(31 downto 0) <= datReg;
                    sel_var := "0000000000001111";
                elsif addrReg(3 downto 2) = "01" then
                    dat_o(127 downto 64) <= (127 downto 64 => '0');
                    dat_o(63 downto 32) <= datReg;
                    dat_o(31 downto 0) <= (31 downto 0 => '0');
                    sel_var := "0000000011110000";
                elsif addrReg(3 downto 2) = "10" then
                    dat_o(127 downto 96) <= (127 downto 96 => '0');
                    dat_o(95 downto 64) <= datReg;
                    dat_o(63 downto 0) <= (63 downto 0 => '0');
                    sel_var := "0000111100000000";
                else
                    dat_o(127 downto 96) <= datReg;
                    dat_o(95 downto 0) <= (95 downto 0 => '0');
                    sel_var := "1111000000000000";
                end if;
            end if;
        else
            dat_o <= (127 downto 0 => '0');
        end if;
        dat_selected <= dat_var;
        sel_internal <= sel_var;
    end process;



end Behavioral;

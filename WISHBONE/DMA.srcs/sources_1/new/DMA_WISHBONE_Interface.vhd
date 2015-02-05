----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/29/2015 10:21:57 PM
-- Design Name: 
-- Module Name: DMA_WISHBONE_Interface - Behavioral
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

entity DMA_WISHBONE_SC_Interface is
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
           
           -- Inputs/outputs for DMA transfer requests, assuming one SLAVE-register set by Processor
           -- May be changed
           
           store_request : in std_logic;
           request_input : in std_logic_vector(95 downto 0); -- ReqDetails (32), base loading address (32), base storing address(32)
           clear : out std_logic -- To flush 
           --clearDetails : out std_logic_vector(31 downto 0; -- For interrupt-details. Currently dummy not in use
           );
end DMA_WISHBONE_SC_Interface;

architecture Behavioral of DMA_WISHBONE_SC_Interface is
    
    -- Internal registers, used when transfering data from DMA to system
    signal type_reg: std_logic_vector(1 downto 0) := "00"; -- 
    signal addr_reg : std_logic_vector(31 downto 0) := (31 downto 0 => '0');
    signal dat_reg : std_logic_vector(31 downto 0) := (31 downto 0 => '0');
    signal active : std_logic := '0';
    signal new_output_ready : std_logic := '0';
    
    -- Output signals from DMA modules
    signal DMA_detail_output : std_logic_vector(33 downto 0) := (33 downto 0 => '0');
    signal DMA_data_output : std_logic_vector(31 downto 0) := (31 downto 0 => '0');
    
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
        dataOut : out std_logic_vector(n-1 downto 0)
           
        );
	end component;
    
    

begin

    -- Set up DMA module
    DMA : DMAToplevel
	port map(
	   clk => clk_i,
	   reset => rst_i,
	   
	   reqIn => request_input,
	   reqStore => store_request,
	   
	   dataIn => dat_i,
	   dataStore => ack_i,
	   
	   outputFull => active,
	   --reqFull => -- Not issue
	   --detaFull => -- Not issue
	   
	   storeOutput => new_output_ready,
	   detailsOut => DMA_details_out,
	   dataOut => DMA_data_out
	   
	);

    -- Setting up outputs
    cyc_o <= active;
    stb_o <= active; -- Works for Single Cycle. May change on more advanced implementation
    addr_o <= addr_reg;
    dat_o <= dat_reg;
    
    active <= ((NOT ack_i AND active) OR (NOT active AND new_output_ready)); -- PROBLEM: How about reset? And process updateRegisters?
    --set_write_enable : process(type_reg)
    --begin
    
    --end process;

    updateRegisters : process(clk_i, rst_i, active, new_output_ready, DMA_details_out, DMA_data_out)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                type_reg <= "00";
                addr_reg <= (31 downto 0 => '0');
                dat_reg <= (31 downto 0 => '0');
                active <= '0'; 
            elsif active = '1' then
            elsif new_output_ready then
                --if (
                
                type_reg <= DMA_details_out(33 downto 32);
                addr_reg <= DMA_details_out(31 downto 0);
                data_reg <= DMA_data_out;
                --if 
                active <= '1';
            end if;
        end if;
    end process;
    
    

end Behavioral;

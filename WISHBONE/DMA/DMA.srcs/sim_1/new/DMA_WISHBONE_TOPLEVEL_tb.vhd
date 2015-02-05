----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/02/2015 11:34:55 PM
-- Design Name: 
-- Module Name: DMA_WISHBONE_TOPLEVEL_tb - Behavioral
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
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DMA_WISHBONE_TOPLEVEL_tb is
--  Port ( );
end DMA_WISHBONE_TOPLEVEL_tb;

architecture Behavioral of DMA_WISHBONE_TOPLEVEL_tb is


    
    -- Mapped signals for component to be tested
     signal clk : STD_LOGIC := '0';
     signal reset : STD_LOGIC := '0';
     signal dat_i : STD_LOGIC_VECTOR (31 downto 0) := (31 downto 0 => '0');
     signal ack_i : STD_LOGIC := '0';
     signal err_i : STD_LOGIC := '0';
     signal rty_i : STD_LOGIC := '0';
     signal tgd_i : STD_LOGIC_VECTOR (2 downto 0) := "000";

    signal adr_o : STD_LOGIC_VECTOR (31 downto 0) := (31 downto 0 => '0');
    signal dat_o : STD_LOGIC_VECTOR (31 downto 0) := (31 downto 0 => '0');
    signal cyc_o : STD_LOGIC := '0';
    signal lock_o : STD_LOGIC := '0';
    signal sel_o : STD_LOGIC_VECTOR (31 downto 0) := (31 downto 0 => '0');
    signal stb_o : STD_LOGIC := '0';
    signal tga_o : STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal tgc_o : STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal tgd_o : STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal we_o : STD_LOGIC := '0';
   
           -- DMA slave inputs
    signal SRegIn : STD_LOGIC_VECTOR (31 downto 0) := (31 downto 0 => '0');
    signal LRegIn : STD_LOGIC_VECTOR (31 downto 0) := (31 downto 0 => '0');
    signal RRegIn : STD_LOGIC_VECTOR (31 downto 0) := (31 downto 0 => '0');
    signal writeRReg : STD_LOGIC := '0';
           -- DMA slave outputs
    signal RRegOut : STD_LOGIC_VECTOR (31 downto 0) := (31 downto 0 => '0');
    signal interrupt : std_logic := '0';
    
    component DMA_WISHBONE_Toplevel
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
    
            -- DMA slave inputs
            SRegIn : in STD_LOGIC_VECTOR (31 downto 0);
            LRegIn : in STD_LOGIC_VECTOR (31 downto 0);
            RRegIn : in STD_LOGIC_VECTOR (31 downto 0);
            writeRReg : in STD_LOGIC;
            -- DMA slave outputs
            RRegOut : out STD_LOGIC_VECTOR (31 downto 0);
            interrupt : out std_logic
    );
    end component;
    
    -- Counters used to monitor number of loads and stores, to be compared to number of expected loads and stores
    signal loads : integer := 0; -- Counts loads issued
    signal stores : integer := 0; -- Counts stores issued
    
    -- Clock period set to 10 ns
    constant clock_period : time := 10 ns;
    
    

begin
    
    UUT : DMA_WISHBONE_Toplevel
		port map (
			clk_i => clk,
            rst_i => reset,
            dat_i => dat_i,
            ack_i => ack_i,
            err_i => err_i,
            rty_i => rty_i,
            tgd_i => tgd_i,
              
            -- WIS
            adr_o => adr_o,
            dat_o => dat_o,
            cyc_o => cyc_o,
            lock_o => lock_o,
            sel_o => sel_o,
            stb_o => stb_o,
            tga_o => tga_o,
            tgc_o => tgc_o,
            tgd_o => tgd_o,
            we_o => we_o,
			
			 SRegIn => SRegIn,
			 LRegIn => LRegIn,
			 RRegIn => RRegIn,
			 writeRReg => writeRReg,
			 -- DMA slav
			 RRegOut => RRegOut,
			 interrupt => interrupt
			
		);

    incrementCounters : process(clk, ack_i, we_o) -- Increment test measurement counters
	begin
	   if rising_edge(clk) then
	       if ack_i = '1' and we_o='0' then -- Load completed
	           loads <= loads + 1;
	       elsif ack_i = '1' and we_o = '1' then -- Store completed
	           stores <= stores + 1;
	       end if;
	   end if;
	end process;

    loadInTransition: process(clk) -- Change input data after load (used to monitor if loaded data is stored, as expected
	begin
		if rising_edge(clk) then
		  if ack_i = '1' and we_o = '0' then
		      dat_i <= STD_LOGIC_VECTOR(UNSIGNED(dat_i) + 3);
		  end if;
		end if;
	end process;
	
	-- Synchronous version
--	acceptRequest : process(clk, cyc_o, stb_o) -- Have mock SLAVE respond with ack_i when both cyc_o and stb_o are asserted
--	begin
--        if rising_edge(clk) then
--            if cyc_o = '1' AND stb_o = '1' then-- AND ack_i = '0' then
--                ack_i <= '1';
--            else
--                ack_i <= '0';
--            end if;
--        end if;
--	end process;

    -- Asynchronous version
--	acceptRequest : process(clk, cyc_o, stb_o) -- Have mock SLAVE respond with ack_i when both cyc_o and stb_o are asserted
--	begin
--        if cyc_o = '1' AND stb_o = '1' then
--            ack_i <= '1';
--        else
--            ack_i <= '0';
--        end if;
--    end process;

    -- Synchronous version, with delay on ack_i signal
--    acceptRequest : process(clk, cyc_o, stb_o) -- Have mock SLAVE respond with ack_i when both cyc_o and stb_o are asserted
--	begin
--        if rising_edge(clk) then
--            if cyc_o = '1' AND stb_o = '1' then
--                ack_i <= '1' after 2ns;
--            else
--                ack_i <= '0' after 2ns;
--            end if;
--        end if;
--	end process;

	-- Synchronous version, tweaked to force the slave to deactivate ack_i together with cyc_o and stb_o (assumed that SLAVES have a way out of this)
	acceptRequest : process(clk, cyc_o, stb_o, ack_i) -- Have mock SLAVE respond with ack_i when both cyc_o and stb_o are asserted
	begin
        if rising_edge(clk) then
            if cyc_o = '1' AND stb_o = '1' AND ack_i = '0' then
                ack_i <= '1';
            else
                ack_i <= '0';
            end if;
        end if;
	end process;
	
	

	CLOCK_SYNTHESIS : process
    begin
        clk <= '1';
        wait for clock_period/2;
        clk <= '0';
        wait for clock_period/2;
    end process;


	-- Add your stimulus here ...
    STIMULUS : process
	begin
		
		-- Resetting registers
		wait for clock_period * 5;
		reset <= '1';
        wait for clock_period * 5;
        reset <= '0';
		
		LRegIn <= "11000000000000000000000000000000";
		SRegIn <= "11000110000000000000000000000000";
		RRegIn <= "00000010110100000000000000000001"; --Count: 45 (excluding base), Byte addressing ON, 0's for ID (currently not in use), final bit set to 1 (for ON). 
		
		wait for clock_period;
		
		-- Remove writeRReg if changed in code
		writeRReg <= '1';
		wait for clock_period;
		writeRReg <= '0';
		                                                                 
        wait;                                                                                  
        -- Expected number of loads and stores: 46 (count 45 + base)                                                                               
		
		
		
		
	end process;

end Behavioral;

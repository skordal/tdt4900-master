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
--use common_defs.v;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DMA_WISHBONE_TOPLEVEL_tb2 is
--  Port ( );
end DMA_WISHBONE_TOPLEVEL_tb2;

architecture Behavioral of DMA_WISHBONE_TOPLEVEL_tb2 is


    
    -- Mapped signals for component to be tested
     signal clk : STD_LOGIC := '0';
     signal reset : STD_LOGIC := '0';
     signal M_dat_i : STD_LOGIC_VECTOR (127 downto 0) := (127 downto 0 => '0');
     
     -- MASTER INPUT SIGNALS
     signal ack_i : STD_LOGIC := '0';
     signal err_i : STD_LOGIC := '0';
     signal rty_i : STD_LOGIC := '0';
     signal M_tgd_i : STD_LOGIC_VECTOR (2 downto 0) := "000";
     signal stall_i : std_logic := '0';
    -- MASTER OUTPUT SIGNALS
    signal adr_o : STD_LOGIC_VECTOR (31 downto 0) := (31 downto 0 => '0');
    signal M_dat_o : STD_LOGIC_VECTOR (127 downto 0) := (127 downto 0 => '0');
    signal cyc_o : STD_LOGIC := '0';
    signal lock_o : STD_LOGIC := '0';
    signal sel_o : STD_LOGIC_VECTOR (15 downto 0) := (15 downto 0 => '0');
    signal stb_o : STD_LOGIC := '0';
    signal tga_o : STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal tgc_o : STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal M_tgd_O : STD_LOGIC_VECTOR (2 downto 0 ) := "000";
    signal we_o : STD_LOGIC := '0';
   
     -- WISHBONE SLAVE INPUTS                              
    signal adr_i : STD_LOGIC_VECTOR (31 downto 0) := (31 downto 0 => '0');            
    signal cyc_i : STD_LOGIC := '0';                                 
    signal lock_i : std_logic := '0';                                
    signal sel_i : std_logic_vector(15 downto 0) := (15 downto 0 => '0');                                 
    signal stb_i : std_logic := '0';                                 
    signal tga_i : std_logic := '0';                                 
    signal tgc_i : std_logic := '0';                                 
    signal we_i : std_logic := '0';
    signal S_dat_i : STD_LOGIC_VECTOR (127 downto 0) := (127 downto 0 => '0');
    signal S_tgd_i : STD_LOGIC_VECTOR (2 downto 0) := "000";                                  
                                                          
    -- WISHBONE SLAVE OUTPUTS
    signal S_dat_o : STD_LOGIC_VECTOR (127 downto 0) := (127 downto 0 => '0');
    signal S_tgd_o : STD_LOGIC_VECTOR (2 downto 0) := "000";                             
    signal ack_o : std_logic := '0';                                
    signal err_o : std_logic := '0';                                
    signal rty_o : std_logic := '0';                                
    signal stall_o : std_logic := '0';    
    
    signal interrupt : std_logic := '0';                          
    
    
    component DMA_WISHBONE_Toplevel
    Port (     
            -- WISHBONE MASTER INPUTS 
              clk_i : in STD_LOGIC;
              rst_i : in STD_LOGIC;
              M_dat_i : in STD_LOGIC_VECTOR (127 downto 0);
              ack_i : in STD_LOGIC;
              err_i : in STD_LOGIC;
              rty_i : in STD_LOGIC;
              M_tgd_i : in STD_LOGIC_VECTOR (2 downto 0);
              stall_i : in STD_LOGIC;
              
              -- WISHBONE MASTER OUTPUTS
              adr_o : out STD_LOGIC_VECTOR (31 downto 0);
              M_dat_o : out STD_LOGIC_VECTOR (127 downto 0);
              cyc_o : out STD_LOGIC;
              lock_o : out STD_LOGIC;
              sel_o : out STD_LOGIC_VECTOR (15 downto 0);
              stb_o : out STD_LOGIC;
              tga_o : out STD_LOGIC_VECTOR (2 downto 0);
              tgc_o : out STD_LOGIC_VECTOR (2 downto 0);
              M_tgd_o : out STD_LOGIC_VECTOR (2 downto 0);
              we_o : out STD_LOGIC;
    
             -- WISHBONE SLAVE INPUTS                              
              adr_i : in STD_LOGIC_VECTOR (31 downto 0);            
              cyc_i : in STD_LOGIC;                                 
              lock_i : in std_logic;                                
              sel_i : in std_logic_vector (15 downto 0);                                 
              stb_i : in std_logic;                                 
              tga_i : in std_logic;                                 
              tgc_i : in std_logic;                                 
              we_i : in std_logic;
              S_tgd_i : in STD_LOGIC_VECTOR (2 downto 0);
              S_dat_i : in STD_LOGIC_VECTOR (127 downto 0);                                  
                                                                    
              -- WISHBONE SLAVE OUTPUTS
              S_dat_o : out STD_LOGIC_VECTOR (127 downto 0);
              S_tgd_o : out STD_LOGIC_VECTOR (2 downto 0);                             
              ack_o : out std_logic;                                
              err_o : out std_logic;                                
              rty_o : out std_logic;                                
              stall_o : out std_logic;
              
              interrupt : out std_logic                              
            
    );
    end component;
    
    -- Counters used to monitor number of loads and stores, to be compared to number of expected loads and stores
    signal loads : integer := 0; -- Counts loads issued
    signal stores : integer := 0; -- Counts stores issued
    
    -- Different input data parts, used to distinguish the four different words in the 128-bit data bus
    signal transferActive : std_logic := '0'; -- Used in test to indicate when DMA transfer is in progress, so that dat0-3 does not update at wrong moments (read/write Slave registers)
    signal dat0 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- := (31 downto 0 => '0');
    signal dat1 : std_logic_vector(31 downto 0) := "10000000000000000000000000000000";-- := (31 downto 0 => '0');
    signal dat2 : std_logic_vector(31 downto 0) := "11000000000000000000000000000000";-- := (31 downto 0 => '0');
    signal dat3 : std_logic_vector(31 downto 0) := "11100000000000000000000000000000";-- := (31 downto 0 => '0');
    signal dat128 : std_logic_vector(127 downto 0) := (127 downto 0 => '0');
    signal Mdat128 : std_logic_vector(127 downto 0) := (127 downto 0 => '0'); -- Data input, directed to the master module
    
    -- Input data to slave registers
    signal RDAT : std_Logic_vector(31 downto 0) := (31 downto 0 => '0');
    signal LDAT : std_Logic_vector(31 downto 0) := (31 downto 0 => '0');
    signal SDAT : std_Logic_vector(31 downto 0) := (31 downto 0 => '0');
    signal RDAT128 : std_logic_vector(127 downto 0) := (127 downto 0 => '0');
    signal SDAT128 : std_logic_vector(127 downto 0) := (127 downto 0 => '0');
    signal LDAT128 : std_logic_vector(127 downto 0) := (127 downto 0 => '0');
    
    -- Clock period set to 10 ns
    constant clock_period : time := 10 ns;
    
    

begin
    
    UUT : DMA_WISHBONE_Toplevel
		port map (
			clk_i => clk,
            rst_i => reset,
            
            -- WB M I
            M_dat_i => M_dat_i,
            ack_i => ack_i,
            err_i => err_i,
            rty_i => rty_i,
            M_tgd_i => M_tgd_i,
            stall_i => stall_i,
              
            -- WB M O
            adr_o => adr_o,
            M_dat_o => M_dat_o,
            cyc_o => cyc_o,
            lock_o => lock_o,
            sel_o => sel_o,
            stb_o => stb_o,
            tga_o => tga_o,
            tgc_o => tgc_o,
            M_tgd_o => M_tgd_o,
            we_o => we_o,
			
			-- WB S I
			adr_i => adr_i,
            cyc_i => cyc_i,
            lock_i => lock_i,
            sel_i => sel_i,
            stb_i => stb_i,
            tga_i => tga_i,
            tgc_i => tgc_i,
            we_i => we_i,
            S_dat_i => S_dat_i,
            S_tgd_i => S_tgd_i,
                    
            -- WB S O
            S_dat_o => S_dat_o,
            S_tgd_o => S_tgd_o,
            ack_o => ack_o,
            err_o => err_o,
            rty_o => rty_o,
            stall_o => stall_o,
            
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
		  if ack_i = '1' and we_o = '0' and transferActive = '1' then
		      --dat_i <= STD_LOGIC_VECTOR(UNSIGNED(dat_i) + 3);
		      dat3 <= STD_LOGIC_VECTOR(UNSIGNED(dat3) + 3);
		      dat2 <= STD_LOGIC_VECTOR(UNSIGNED(dat2) + 3);
		      dat1 <= STD_LOGIC_VECTOR(UNSIGNED(dat1) + 3);
		      dat0 <= STD_LOGIC_VECTOR(UNSIGNED(dat0) + 3);
		      --dat_i <= dat128;
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
	acceptDMALoad : process(clk, cyc_o, stb_o, ack_i) -- Have mock SLAVE respond with ack_i when both cyc_o and stb_o are asserted
	begin
        if rising_edge(clk) then
            if cyc_o = '1' AND stb_o = '1' AND ack_i = '0' then
                ack_i <= '1';
            else
                ack_i <= '0';
            end if;
        end if;
	end process;
	
	-- Read or write to slave registers, finish off single read/write
--	acceptRegisterOperation : process(clk, cyc_i, stb_i, ack_o)
--	begin
--	   if rising_edge(clk) then
--	       if cyc_i = '1' and stb_i = '1' AND ack_o = '1' then
--	           cyc_i <= '0';
--	           stb_i <= '0';
--	       else
--	           cyc_i <= cyc_i;
--	           stb_i <= stb_i;
--	       end if;
--	   end if;
--	end process;
	
	
	
	interruptDetected : process(clk, interrupt)
	begin
	   if rising_edge(clk) then
	       if interrupt = '1' then
	          -- cyc_o <= '1';
	           --stb_i <= '1';
	       end if;
	   end if;
	end process;
	
	
	-- Setting up 128-bit signals
    Mdat128 <= dat3 & dat2 & dat1 & dat0;
    RDAT128 <= RDAT & RDAT & RDAT & RDAT;
    SDAT128 <= SDAT & SDAT & SDAT & SDAT;
    LDAT128 <= LDAT & LDAT & LDAT & LDAT;
            
	M_dat_i <= Mdat128; --Always Mdat128 in M_dat_i

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
	
	   -- Phases: 0 - reset, 1 - Write to registers, 2 - read the registers, 3 - activate DMA, 4 - Handle interrupt and read registers 
	
	  
	   
		-- PHASE 0
		-- Resetting registers
		wait for clock_period * 5;
		reset <= '1';
        wait for clock_period * 5;
        reset <= '0';
		
		-- PHASE 1
		LDAT <= "11000000000000000000000000000000";
		SDAT <= "11000110000000000000000000000000";
		RDAT <= "00000010110110000000000000000000"; --Count: 45 (excluding base), Byte addressing ON, 0's for ID (currently not in use), final bit set to 1 (for ON). 
		
		wait for clock_period;
		-- Write LDAT
        adr_i <= "00000000000000000000000000000000"; --LREG0
        S_dat_i <= LDAT128;
        we_i <= '1';        
		
		wait for clock_period;
		
		cyc_i <= '1';
		stb_i <= '1';
		
		wait for clock_period * 2;
		
		cyc_i <= '0';
        stb_i <= '0';
                
		wait for clock_period;
		-- Write SDAT
        adr_i <= "00000000000000000000000000000100"; --SREG0
        S_dat_i <= SDAT128;
        we_i <= '1';        
                
        wait for clock_period;
                
        cyc_i <= '1';
        stb_i <= '1';
                
        wait for clock_period * 2;
                
        cyc_i <= '0';
        stb_i <= '0';
                        
        wait for clock_period;
                
        -- Write RDAT
        adr_i <= "00000000000000000000000000001000"; --SREG0
        S_dat_i <= RDAT128;
        we_i <= '1';        
                        
        wait for clock_period;
                        
        cyc_i <= '1';
        stb_i <= '1';
                
        wait for clock_period * 2;
                
        cyc_i <= '0';
        stb_i <= '0';
                        
        wait for clock_period;
               
               
        -- PHASE 2                
        -- Read registers.
        
        we_i <= '0';
        
        -- LDAT                         
		adr_i <= "00000000000000000000000000000000"; --LREG0
		wait for clock_period;
		
		cyc_i <= '1';
        stb_i <= '1';
                
        wait for clock_period * 2;
                
        cyc_i <= '0';
        stb_i <= '0';
                        
        wait for clock_period;
		
		-- SDAT                         
        adr_i <= "00000000000000000000000000000100"; --SREG0
        wait for clock_period;
                
        cyc_i <= '1';
        stb_i <= '1';
                
        wait for clock_period * 2;
                
        cyc_i <= '0';
        stb_i <= '0';
                        
        wait for clock_period;
                
		-- RDAT                         
        adr_i <= "00000000000000000000000000001000"; --RREG0
        wait for clock_period;
                        
        cyc_i <= '1';
        stb_i <= '1';
                
        wait for clock_period * 2;
                
        cyc_i <= '0';
        stb_i <= '0';
                        
        wait for clock_period * 10;
		
		
		
		-- PHASE 3
		-- Activate DMA
		-- Expected number of loads and stores: 46 (count 45 + base)      
		
		RDat(0) <= '1';
		wait for clock_period;
		S_dat_i <= RDAT128;
		we_i <= '1';
		cyc_i <= '1';
        stb_i <= '1';
                        
        wait for clock_period * 2;
                        
        cyc_i <= '0';
        stb_i <= '0';
        we_i <= '0';
        transferActive <= '1'; -- For updating the inputs to dat_i per transfer
        --dat_i <= DAT128;
		                                                                 
        wait for clock_period * 30;                                                                                                                                     
		
		-- PHASE 4
		-- Read R-register during transfer (will happen simultaneously with DMA transfer due to the test environment, will ideally happen alternately in real environment)
		-- May happen optinally, but is not compulsory
		
        adr_i <= "00000000000000000000000000001000"; --RREG0
        wait for clock_period;
		
        cyc_i <= '1';
        stb_i <= '1';
		
		wait for clock_period * 2;
		
        cyc_i <= '0';
        stb_i <= '0';
		
		wait for clock_period * 270;
        
        -- PHASE 5:
        -- Read R-register after transfer
        -- Should always happen at least once after interrupt due to DMA finished transfering data.
                
        adr_i <= "00000000000000000000000000001000"; --RREG0
        wait for clock_period;
                
        cyc_i <= '1';
        stb_i <= '1';
        
        wait for clock_period * 2;
                
        cyc_i <= '0';
        stb_i <= '0';
        
		wait;
		
	end process;

end Behavioral;

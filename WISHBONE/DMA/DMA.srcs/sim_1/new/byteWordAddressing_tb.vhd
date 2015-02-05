----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/20/2015 06:50:34 PM
-- Design Name: 
-- Module Name: byteWordAddressing_tb - Behavioral
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
-- Purpose with test: Test word-addressing and byte-addressing

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

	-- Add your library and packages declaration here ...

entity byteWordAddressing_tb is
end byteWordAddressing_tb;

architecture TB_ARCHITECTURE of byteWordAddressing_tb is
	-- Component declaration of the tested unit
	component DMATopLevel
		--generic( n : integer := 32; -- 32-bit addresses
        --         m : integer := 32;
        --         u : integer := 96;    -- ReqDetails, 32 bit set as standard
        --         p : integer := 64;
        --         bufferDepth : integer := 8
        --);
		port(
           -- General inputs
           clk : in std_logic;
           reset : in std_logic;
           
           -- Inputs to request buffer
           reqIn : in std_logic_vector(96-1 downto 0);
           reqStore : in std_logic;
           
           -- Inputs to data buffer
           dataIn : in std_logic_vector(64-1 downto 0);
           dataStore : in std_logic;
           
           -- Input from output bus to channels
           outputFull : in std_logic;
           
           -- Output from buffers
           reqFull : out std_logic;
           dataFull : out std_logic;
           
           -- Output from DMA
           storeOutput : out std_logic;
           detailsOut : out std_logic_vector((32+2)-1 downto 0);
           dataOut : out std_logic_vector(32-1 downto 0)
           
           );
		end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal clk : STD_LOGIC := '0';
	signal reset : std_logic := '0';
	

	-- All inputs 
	signal reqIn : std_logic_vector(95 downto 0) := (95 downto 0 => '0');
	signal reqStore : std_logic := '0';
	signal dataIn : std_logic_vector(63 downto 0) := (63 downto 0 => '0');
    signal dataStore : std_logic := '0';
	
	signal outputFull : std_logic := '0';
	
	-- All outputs
	signal reqFull : std_logic := '0'; 
	signal dataFull : std_logic := '0';
	
	signal storeOutput : std_logic := '0';
	signal detailsOut : std_logic_vector (33 downto 0) := (33 downto 0 => '0');
	signal dataOut : std_logic_vector (31 downto 0) := (31 downto 0 => '0');
	
	-- Test-related signals
	
	-- Used to delay incoming loaddata by one cycle extra from when load is issued from DMA topmodule.
	-- They are used as buffer between output and loadIDinput
	signal loadIDTransition : std_logic_vector(31 downto 0) := (31 downto 0 => '0');
	signal loadInTransit : std_logic:= '0';
	signal CMD : std_logic_vector (1 downto 0) := "00";
	signal data : std_logic_vector (31 downto 0) := (31 downto 0 => '0');
	
	constant clock_period : time := 10 ns;
	
	-- Counters for measuring test
	signal loads : integer := 0; -- Counts loads issued
	signal stores : integer := 0; -- Counts stores issued
	signal interrupts : integer := 0; -- Counts interrupts issued
	signal inactive : integer := 0; -- Counts when there are no outputs (block or inactive). May be useful to calculate number of cycles from request is sent in till the system if operational
	signal blocks : integer := 0;
	
	-- Base addresses for loadAddresses, StoreAddresses, ReqID and counts. Used for setting up requests.
	-- Number of requests for this version: 1
	signal load1 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
	signal load2 : std_logic_vector(31 downto 0) := "11111111111111110000000011110000";
	--signal load3 : std_logic_vector(31 downto 0) := "00000000000011110000110011000000";
	--signal load4 : std_logic_vector(31 downto 0) := "00001111000011001100110011000000";
	
	signal store1 : std_logic_vector(31 downto 0) := "11001100110011001100110000000000";
    signal store2 : std_logic_vector(31 downto 0) := "11110000111100001111000011110000";
    --signal store3 : std_logic_vector(31 downto 0) := "00001111111111111111111111100000";
    --signal store4 : std_logic_vector(31 downto 0) := "00000000000000001111111111111111";
    
    signal count1 : std_logic_vector(11 downto 0) := "000000001010"; -- 10 + 1
    signal count2 : std_logic_vector(11 downto 0) := "000000001010"; -- 10 + 1
    
    signal req1 : std_logic_vector(95 downto 0) := (95 downto 0 => '0');
    signal req2 : std_logic_vector(95 downto 0) := (95 downto 0 => '0');
    --signal req3 : std_logic_vector(95 downto 0) := (95 downto 0 => '0');
    --signal req4 : std_logic_vector(95 downto 0) := (95 downto 0 => '0');
        
	
begin
	
	req1 <= load1 & store1 & count1 & '0' & "0000001" & "000000000000"; -- Same details for both, except byte- or word addressing
	req2 <= load1 & store1 & count1 & '1' & "0000001" & "000000000000"; 
	--req2 <= load1 & store1 & count2 & '1' & "0000011" & "0000000000000";
	--req3 <= load3 & store3 & count1 & "0001100" & "0000000000000";
	--req4 <= load4 & store4 & count1 & "1110001" & "0000000000000";
	
	CMD(1 downto 0) <= detailsOut(33 downto 32);
	
	-- Unit Under Test port map
	UUT : DMATopLevel
		port map (
			-- INPUTS
			clk => clk,
			reset => reset,
			reqIn => reqIn,
			reqStore => reqStore,
			dataIn => dataIn,
			dataStore => dataStore,
			outputFull => outputFull,
			
			reqFull => reqFull,
			dataFull => dataFull,
			storeOutput => storeOutput,
			detailsOut => detailsOut,
			dataOut => dataOut
		);

	-- Add your stimulus here ...
	CLOCK_SYNTHESIS : process
    begin
        clk <= '1';
        wait for clock_period/2;
        clk <= '0';
        wait for clock_period/2;
    end process;
	
	
	-- Two next processes automatically handle loads, so that requested loads' IDs are sent in together with data
	-- The choice is to have a little delay (assumed to be 2 cycles)
	-- Set mid-buffer for load, make sure
	loadInTransition: process(clk, CMD, storeOutput, detailsOut)
	begin
		if rising_edge(clk) then
			if storeOutput = '1' and CMD = "00" then
			     loadIDTransition <= detailsOut(31 downto 0);
			     loadInTransit <= '1';
			else
                 loadInTransit <= '0'; -- Prevent activating input
			end if;
		else
			--nothing
		end if;
	end process;
	
	pushLoad : process(clk, loadInTransit, loadIDTransition)
	begin
	   if rising_edge(clk) then
	       if loadInTransit = '1' then
	           dataIn(63 downto 32) <= loadIDTransition;
	           dataIn(31 downto 0) <= data;
	           data <= std_logic_vector(unsigned(data)+3); -- Increment data 3 for every data in. Does not care about which LoadID it belonds to in this test, only ID is important
	           dataStore <= '1';
	       else 
	           dataStore <= '0';
	       end if;
	   end if;
	end process;
	
	-- Increments test counters for loads, stores and interrupts. They are only for reading test results only, and does not affect behaviour
	incrementCounters : process(clk, storeOutput, outputFull, CMD, loads, stores, interrupts, blocks, inactive)
	begin
	   if rising_edge(clk) then
	       if storeOutput = '1' then 
	           if CMD = "00" then
	               loads <= loads + 1;
	           elsif CMD = "01" then
	               stores <= stores + 1;
	           elsif CMD(1) = '1' then
	               interrupts <= interrupts + 1;
	           else
	               -- Nothing
	           end if;
	       elsif outputFull = '1' then
	           blocks <= blocks + 1;
	       else
	           inactive <= inactive + 1;
	       end if;
	   end if;
	end process;
	
	
	STIMULUS : process
	begin
		
		reset <= '1';
		wait for clock_period * 5;
		reset <= '0';
		
		-- Test will first perform 11 loads and stores with word-addressing (increment counters by 1)
		-- Then 11 loads and stores with byte-addressing (increment counters by 4)
		-- There are two tests for both, to check if transition word -> byte -> word -> byte
		wait for clock_period * 10;
		
		reqIn <= req1;
		reqStore <= '1';
		wait for clock_period;
		reqStore <= '0';
		
		wait for clock_period * 30; --Should cover first test
		
		reqIn <= req2;
        reqStore <= '1';
        wait for clock_period;
        reqStore <= '0';
                
        wait for clock_period * 30; --Should cover second test
                
        reqIn <= req1;        
 		reqStore <= '1';        
 		wait for clock_period;        
 		reqStore <= '0';        
 		        
 		wait for clock_period * 30; --Should cover first test        
 		        
 		reqIn <= req2;        
         reqStore <= '1';        
         wait for clock_period;        
         reqStore <= '0';               
	                	
	       wait for clock_period * 30; --Should cover second test	
		
		-- Expected end results on counters: 44 loads, 44 stores, 4 interrupt, 0 blocks 
		-- First and third FLA + FSA: (11)..00001010
		-- Second and fourth FLA + FSA: (11)..000101000 (notice the double shift to left)
		
		wait;
		
		-- DONE
		
		
		
		
	end process;
end TB_ARCHITECTURE;

--configuration TESTBENCH_FOR_controller of controller_tb is
	--for TB_ARCHITECTURE
		--for UUT : aController
			--use entity work.controller(controller);
			--end for;
		--end for;
	--end TESTBENCH_FOR_controller;

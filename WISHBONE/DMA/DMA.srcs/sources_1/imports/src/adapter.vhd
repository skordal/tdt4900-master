library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity adapter is
	port (
	   clk : in std_logic;
	   emptyIn : in std_logic;
	   reqUpdateIn : in std_logic;
	   
	   popOut : out std_logic;
	   requestOut : out std_logic
	
	);
end adapter;

architecture arch of adapter is
    -- Combinatorical signals
    signal registerIn : std_logic := '0';
    signal reqisterResult : std_logic := '0';
    signal regPopResult : std_logic := '0';
    signal reqUpdateRegister : std_logic := '0';
    
    -- Register
    signal request : std_logic := '0';


begin

    -- Combinatorics
    registerIn <= NOT emptyIn OR reqisterResult;
    reqisterResult <= request AND NOT reqUpdateIn;
    regPopResult <= NOT request OR (request AND reqUpdateIn);
    
    -- Outputs
    requestOut <= request;
    popOut <=  NOT emptyIn AND regPopResult;
    
    -- Register
    updateRegister : process(clk, registerIn)
    begin
        if rising_edge(clk) then
            request <= registerIn;
        end if;
    end process;

end arch;
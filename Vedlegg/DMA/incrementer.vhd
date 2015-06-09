library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity incrementer is
	generic(n: integer := 32);
	port (
		opt : in std_logic;
		inputValue: in std_logic_vector(n-1 downto 0);
		
		result: out std_logic_vector(n-1 downto 0)
		);
end incrementer;

architecture arch of incrementer is
begin
	change : process(inputValue, opt)
	begin
		if opt = '0' then
		--	result <= std_logic_vector(unsigned(inputValue) + 1); --PLUS
		  result <= std_logic_vector(unsigned(inputValue) + 4); --PLUS
		else 
		--	result <= std_logic_vector(unsigned(inputValue) - 1); --MINUS 
		  result <= std_logic_vector(unsigned(inputValue) - 4); --MINUS
		end if;
	end process;
end arch;
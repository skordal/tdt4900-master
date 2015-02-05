library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity adder is
	generic(n: integer := 32);
	port (
		input0 : in std_logic_vector(n-1 downto 0);
		input1: in std_logic_vector(n-1 downto 0);
		
		result: out std_logic_vector(n-1 downto 0)
		);
end adder;

architecture arch of adder is
begin
	result <= std_logic_vector(unsigned(input0) + unsigned(input1));
end arch;
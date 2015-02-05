library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity manSubtractor is
	generic(n: integer := 32);
	port (
		opt : in std_logic;
		input0: in std_logic_vector(n-1 downto 0);
		input1: in std_logic_vector(n-1 downto 0);
		
		result: out std_logic_vector(n-1 downto 0)
		);
end manSubtractor;

architecture activate of manSubtractor is
begin
	selection: process(opt, input0, input1)
	begin
		if opt = '1' then
			result <= std_logic_vector(unsigned(input0) - unsigned(input1)); 	-- Subtractor is on
		else
			result <= input0;			-- Subtractor is off (useful for fixed address modes)
		end if;
	end process;
end activate;
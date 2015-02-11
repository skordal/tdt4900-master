library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity AMMux is
	port (
		opt: in std_logic;
		AMInput0: in std_logic;
		AMInput1: in std_logic;
		AMOutput: out std_logic
	);
end AMMux;

architecture arch of AMMux is
begin
	selectOutput : process (opt, AMInput0, AMInput1)
	begin
		if opt ='1' then
			AMOutput <= AMInput1;
		else
			AMOutput <= AMInput0;
		end if;
	end process;
end arch;
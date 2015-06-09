library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity dataMux is
	generic(n: integer := 32);
	port (
		opt: in std_logic;
		dataInput0: in std_logic_vector(n-1 downto 0);
		dataInput1: in std_logic_vector(n-1 downto 0);
		dataOut: out std_logic_vector(n-1 downto 0)
	);
end dataMux;

architecture arch of dataMux is
begin
	selectOutput : process (opt, dataInput0, dataInput1)
	begin
		if opt ='1' then
			dataOut <= dataInput1;
		else
			dataOut <= dataInput0;
		end if;
	end process;
end arch;
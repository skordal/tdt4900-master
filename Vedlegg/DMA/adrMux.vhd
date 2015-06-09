library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity adrMux is
	generic(n: integer := 34; -- Two extra bits to determine difference between load, store and intterupt. Must be recognized by the output handler. 
			m: integer := 3;
			b: integer := 3);
	port (
		opt: in std_logic_vector(m-1 downto 0);
		interruptInput: in std_logic_vector(n+b-1 downto 0);
		storeInput0: in std_logic_vector(n+b-1 downto 0);
		storeInput1: in std_logic_vector(n+b-1 downto 0);
		loadInput0: in std_logic_vector(n+b-1 downto 0);
		loadInput1: in std_logic_vector(n+b-1 downto 0);
		
		adrOutput : out std_logic_vector(n+b-1 downto 0)
	);
end adrMux;

architecture arch of adrMux is
begin
	selectOutput : process (opt, interruptInput, storeInput0, storeInput1, loadInput0, loadInput1)
	begin
		
	if opt = "000" then 
		adrOutput <= interruptInput;
	elsif opt = "001" then
		adrOutput <= storeInput0;
	elsif opt = "010" then
		adrOutput <= storeInput1;
	elsif opt = "011" then
		adrOutput <= loadInput0;
	elsif opt = "100" then
		adrOutput <= loadInput1;
	else 
		adrOutput <= (n+b-1 downto 0 => '0'); -- Should not happen, except of external uses of input don't cares
	end if;
		
	
--		case opt is
--			when "000" => adrOutput <= interruptInput;
--			when "001" => adrOutput <= storeInput0;
--			when "010" => adrOutput <= storeInput1;
--			when "011" => adrOutput <= loadInput0;
--			when "100" => adrOutput <= loadInput1;
--			when others => adrOutput <= (n-1 downto 0 => '-'); -- Should not happen, except of external uses of input don't cares
--		end case;
	end process;
end arch;
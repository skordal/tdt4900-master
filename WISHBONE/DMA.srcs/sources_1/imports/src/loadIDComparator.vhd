library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity loadIDComparator is
	generic(
		n: integer := 32
	);
	port (						
		-- Input from fifo						   
		loadIDIn : in std_logic_vector(n-1 downto 0);
		
		-- Input from channels
		loadIDCheck0 : in std_logic_vector(n-1 downto 0);
		loadIDCheck1 : in std_logic_vector(n-1 downto 0);
		
		-- Output to channels
		rdy0 : out std_logic;
		rdy1 : out std_logic
		
								
		);
end loadIDComparator;

architecture arch of loadIDComparator is
													  
	
begin
			  
	
	compare : process(loadIDCheck0, loadIDCheck1, loadIDIn)
	begin
		if loadIDCheck0 = loadIDIn then
			rdy0 <= '1';
			rdy1 <= '0';
		elsif loadIDCheck1 = loadIDIn then
			rdy0 <= '0';
			rdy1 <= '1';
		else 
			rdy0 <= '0';
			rdy1 <= '0';
		end if;
	end process;		  
	
end arch;



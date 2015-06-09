library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity srcIDComparator is
	generic(
		n: integer := 32
	);
	port (						
		-- Input from fifo						   
		srcIDIn : in std_logic_vector(n-1 downto 0);
		
		-- Input from channels
		srcIDCheck0 : in std_logic_vector(n-1 downto 0);
		srcIDCheck1 : in std_logic_vector(n-1 downto 0);
		
		-- Output to channels
		rdy0 : out std_logic;
		rdy1 : out std_logic
		
								
		);
end srcIDComparator;

architecture arch of srcIDComparator is
													  
	
begin
			  
	
	compare : process(srcIDCheck0, srcIDCheck1, srcIDIn)
	begin
		if srcIDCheck0 = srcIDIn then
			rdy0 <= '1';
			rdy1 <= '0';
		elsif srcIDCheck1 = srcIDIn then
			rdy0 <= '0';
			rdy1 <= '1';
		else 
			rdy0 <= '0';
			rdy1 <= '0';
		end if;
	end process;		  
	
end arch;



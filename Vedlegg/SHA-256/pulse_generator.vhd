-- Smallthings
-- (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <http://github.com/skordal/smallthings/issues>

-- Pulse generator module; generates a one cycle pulse in response to the input
-- signal going high.

library ieee;
use ieee.std_logic_1164.all;

entity pulse_generator is
	port(
		clk    : in  std_logic;
		reset  : in  std_logic;
		input  : in  std_logic;
		output : out std_logic
	);
end entity pulse_generator;

architecture behaviour of pulse_generator is
	signal idle : boolean;
begin

	process(clk, reset)
	begin
		if reset = '1' then
			idle <= true;
		elsif rising_edge(clk) then
			output <= '0';
			if idle then
				if input = '1' then
					idle <= false;
					output <= '1';
				end if;
			else
				if input = '0' then
					idle <= true;
				end if;
			end if;
		end if;
	end process;

end architecture behaviour;

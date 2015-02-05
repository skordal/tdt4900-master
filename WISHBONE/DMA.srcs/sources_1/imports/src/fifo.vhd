-- Smallthings
-- (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <http://github.com/skordal/smallthings/issues>

library ieee;
use ieee.std_logic_1164.all;

entity fifo is
	generic(
		depth : natural := 16;
		width : natural := 64
	);
	port(
		-- Control lines:
		clk   : in std_logic;
		reset : in std_logic;

		-- Status lines:
		full  : out std_logic;
		empty : out std_logic;

		-- Data in:
		input : in std_logic_vector(width - 1 downto 0);
		push  : in std_logic;

		-- Data out:
		output : out std_logic_vector(width - 1 downto 0);
		pop    : in  std_logic
	);
end entity fifo;

architecture behaviour of fifo is
	type memory_type is array(0 to depth - 1) of std_logic_vector(width - 1 downto 0);
	signal memory : memory_type;

	subtype index_type is integer range 0 to depth - 1;
	signal top, bottom : index_type; -- Elements are inserted at the top and removed from the bottom.

	type fifo_op is (FIFO_POP, FIFO_PUSH);
	signal prev_op : fifo_op;
begin
	empty <= '1' when top = bottom and prev_op = FIFO_POP else '0';
	full <= '1' when top = bottom and prev_op = FIFO_PUSH else '0';

	update: process(clk, reset)
	begin
		if reset = '1' then
			top <= 0;
			bottom <= 0;
			prev_op <= FIFO_POP;
		elsif rising_edge(clk) then
			if push = '1' then
				memory(top) <= input;
				top <= (top + 1) mod depth;
				prev_op <= FIFO_PUSH;
			end if;
			
			if pop = '1' then
				output <= memory(bottom);
				bottom <= (bottom + 1) mod depth;
				prev_op <= FIFO_POP;
			end if;
		end if;
	end process update;

end architecture behaviour;
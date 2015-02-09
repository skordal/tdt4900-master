// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include "shmac.h"

void main(void)
{
	shmac_printf("The Great and Awesome Heterogeneous Bitcoin Miner Project\n\r");
	shmac_printf("By Kristian K. Skordal and Torbjorn Langland\n\r\n\r");

	int x, y;
	shmac_get_tile_loc(&x, &y);
	shmac_printf("Tile location: (%d, %d)\n\r\n\r", x, y);


	while(1); // Burn cycles until Amber implements something like wfi
}


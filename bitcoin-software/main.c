// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include <stdint.h>

#include "sha256.h"
#include "shmac.h"

void main(void)
{
	shmac_printf("The Great and Awesome Heterogeneous Bitcoin Miner Project\n\r");
	shmac_printf("By Kristian K. Skordal and Torbjorn Langland\n\r\n\r");

	int x, y;
	shmac_get_tile_loc(&x, &y);
	shmac_printf("Tile location: (%d, %d)\n\r\n\r", x, y);

	shmac_printf("Resetting SHA256 accelerator... ");
	sha256_reset();
	shmac_printf("ok\n\r");

	uint8_t hash[32];
	char hash_string[65];

	sha256_get_hash(hash);
	sha256_format_hash(hash, hash_string);
	shmac_printf("Default/reset hash value: %s\n\r", hash_string);

	shmac_printf("\n\rEnd programme.\n\r");
	while(1); // Burn cycles until Amber implements something like wfi
}


// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#ifndef BRAM_H
#define BRAM_H

#include <stdint.h>

#ifndef NUM_SCRATCHPADS
#define NUM_SCRATCHPADS 1
#endif

// Allocates memory in the specified BRAM (scratchpad tile):
void * bram_allocate(int n, unsigned int size) __attribute((malloc));

#endif


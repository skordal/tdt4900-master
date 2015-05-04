// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include "bram.h"

static volatile uint32_t * bram_ends;

// Initialization function, called from start.S:
void bram_initialize(void)
{
	bram_ends = (uint32_t *) 0xf8000000U;
	bram_ends[0] = (uint32_t) (0xf8000000U + NUM_SCRATCHPADS * sizeof(uint32_t));
	for(int i = 1; i < NUM_SCRATCHPADS; ++i)
		bram_ends[i] = 0xf8000000U + i * 0x01000000U;
}

void * bram_allocate(int n, unsigned int size)
{
	void * retval = (void *) bram_ends[n];
	bram_ends[n] += (size + 3) & -4;
	return retval;
}


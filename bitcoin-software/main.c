// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include <stdint.h>

#include "irq.h"
#include "sha256.h"
#include "shmac.h"
#include "timer.h"

// The worker thread structures are statically allocated for now. Remember to
// update NUM_WORKERS to the correct number of worker CPUs (total number of CPUs
// minus one) in the Makefile when changing the hardware!

void timer_callback(void * data)
{
	shmac_printf("CPU%d: Ping!\n\r");
}

void main(void)
{
	if(shmac_get_tile_cpu_id() == 0)
	{
		shmac_initialize();
		shmac_printf("The Great and Awesome Heterogeneous Bitcoin Miner Project\n\r");
		shmac_printf("By Kristian K. Skordal and Torbjorn Langland\n\r\n\r");

//		shmac_set_ready();
	}

	shmac_printf("CPU%d: CPU %d of %d checking in!\n\r", shmac_get_tile_cpu_id(),
		shmac_get_tile_cpu_id() + 1, shmac_get_cpu_count());

	timer_start(0, 60000, TIMER_SCALE_1, true, timer_callback, 0); 

	shmac_printf("CPU%d: End of main.\n\r", shmac_get_tile_cpu_id());
}


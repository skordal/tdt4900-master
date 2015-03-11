// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include <stdint.h>
#include <stdbool.h>

#include "mm.h"
#include "sha256.h"
#include "shmac.h"
#include "timer.h"

void timer_callback(void * data)
{
	static int counter = 0;

	if(counter < 4)
		++counter;
	else {
		shmac_printf("PING\n\r");
		counter = 0;
	}
}

void main(void)
{
	if(shmac_get_tile_cpu_id() == 0)
	{
		shmac_initialize();
	}

	timer_start(0, 60000, TIMER_SCALE_1, true, timer_callback, 0);

	shmac_printf("READY\n\r");

	while(1); // Burn cycles until Amber implements something like wfi


}


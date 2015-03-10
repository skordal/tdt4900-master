// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include <stdint.h>

#include "irq.h"
#include "shmac.h"

static irq_handler_func handlers[IRQ_MAXNUM][NUM_CPUS] = {{0}};
static volatile uint32_t * irq_controller = IRQ_IC0_BASE;

// IRQ handler function:
void irq_handler(void)
{
	uint32_t irq_status = irq_controller[IRQ_IC_STATUS];
	for(int i = 0; i < IRQ_MAXNUM; ++i)
		if(((irq_status >> i) & 1) && handlers[i][shmac_get_tile_cpu_id()] != 0)
			handlers[i][shmac_get_tile_cpu_id()](i);
}

// Clears the interrupt mask, called from start.S:
void irq_initialize(void)
{
	irq_controller[IRQ_IC_ENABLECLR] = 0xffffffff;
}

void irq_set_handler(int irq, int cpu, irq_handler_func handler)
{
	shmac_printf("CPU%d: Setting handler for IRQ %d to %x\n\r",
		cpu, irq, handler);
	handlers[irq][cpu] = handler;
	irq_controller[IRQ_IC_ENABLESET] = 1 << irq;
}

void irq_remove_handler(int irq, int cpu)
{
	handlers[irq][cpu] = 0;
	irq_controller[IRQ_IC_ENABLECLR] = 1 << irq;
}


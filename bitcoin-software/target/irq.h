// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#ifndef IRQ_H
#define IRQ_H

// IRQ controller 0 base:
#define IRQ_IC0_BASE	(volatile void *) 0xfffe2000

// IRQ controller register offsets:
#define IRQ_IC_STATUS		(0x00 >> 2)
#define IRQ_IC_ENABLESET	(0x08 >> 2)
#define IRQ_IC_ENABLECLR	(0x0c >> 2)

// Total number of interrupts supported:
#ifndef IRQ_MAXNUM
#define IRQ_MAXNUM		31
#endif

// IRQ handler function:
typedef void (*irq_handler_func)(int irq);

// Sets an IRQ handler:
void irq_set_handler(int irq, irq_handler_func handler);

// Removes an IRQ handler:
void irq_remove_handler(int irq);

#endif


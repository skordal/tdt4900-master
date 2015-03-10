// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#ifndef TIMER_H
#define TIMER_H

#include <stdbool.h>
#include <stdint.h>

// Timer module base addresses:
#define TIMER0_BASE	(volatile void *) 0xfffe1000
#define TIMER1_BASE	(volatile void *) 0xfffe1100
#define TIMER2_BASE	(volatile void *) 0xfffe1200

// Timer register offsets:
#define TIMER_LOAD	(0x00 >> 2)
#define TIMER_VALUE	(0x04 >> 2)
#define TIMER_CTRL	(0x08 >> 2)
#define TIMER_CLR	(0x0c >> 2)

// Control register bits:
#define TIMER_CTRL_ENABLE	7
#define TIMER_CTRL_PERIODIC	6
#define TIMER_CTRL_SCALE	2

// Timer IRQ numbers:
#define TIMER0_IRQ	2
#define TIMER1_IRQ	3
#define TIMER2_IRQ	4

enum timer_scale_factor
{
	TIMER_SCALE_256 = 0,
	TIMER_SCALE_16 = 1,
	TIMER_SCALE_1 = 2,
};

// Timer callback function:
typedef void (*timer_callback_func)(void * data);

// Starts a timer; arguments:
// * timer - which timer to use, 0, 1 or 2
// * count - which count to load into the timer.
// * scale - a scale factor, see Redmine
// * repeating - if the timer should reload after overflow
// * callback - function called on interrupt
// * data for the callback
void timer_start(unsigned int timer, uint32_t count, enum timer_scale_factor scale,
	bool repeating, timer_callback_func callback, void * data);

#endif


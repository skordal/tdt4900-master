// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#ifndef SHMAC_H
#define SHMAC_H

#include <stdint.h>

// SHMAC register blocks:
#define SHMAC_TILE_BASE	(volatile void *) 0xfffe0000
#define SHMAC_SYS_BASE	(volatile void *) 0xffff0000

// SHMAC tile register offsets (in 32-bit words):
#define SHMAC_TILE_CPU_ID	(0x00 >> 2)
#define SHMAC_TILE_X		(0x04 >> 2)
#define SHMAC_TILE_Y		(0x08 >> 2)

// SHMAC Interrupt controller 0 register offsets:
#define SHMAC_IC_IRQ_STATUS	(0x

// SHMAC system register offsets (in 32-bit words):
#define SHMAC_SYS_OUT_DATA	(0x00 >> 2)
#define SHMAC_SYS_IN_DATA	(0x10 >> 2)
#define SHMAC_SYS_INT_STATUS	(0x20 >> 2)
#define SHMAC_SYS_CPU_COUNT	(0x40 >> 2)
#define SHMAC_SYS_READY		(0x50 >> 2)

// -------------- INITIALIZATION FUNCTION --------------

// Initializes the SHMAC library, use this before any of the functions below!
void shmac_initialize(void);

// -------------- TILE FUNCTIONS --------------

// Gets the CPU ID of the current tile:
int shmac_get_tile_cpu_id(void);

// Gets the total number of CPUs in the system:
int shmac_get_cpu_count(void);

// Gets the location of the current tile:
void shmac_get_tile_loc(int * x, int * y);

// Starts the rest of the CPUs after CPU 0 is done initializing:
void shmac_set_ready(void);

// -------------- DEBUG FUNCTIONS --------------

// Prints a message over the serial port.
// This function recognizes the following arguments:
// 	%x = prints a 32-bit hexadecimal number
//	%s = prints a string
//	%c = prints a character
void shmac_printf(const char * format, ...);

// Reads a character from the serial port:
char shmac_getc(void);

#endif


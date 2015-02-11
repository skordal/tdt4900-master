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
#define SHMAC_TILE_X	(0x04 >> 2)
#define SHMAC_TILE_Y	(0x08 >> 2)

// SHMAC system register offsets (in 32-bit words):
#define SHMAC_SYS_OUT_DATA	(0x00 >> 2)
#define SHMAC_SYS_INT_STATUS	(0x20 >> 2)


// -------------- TILE FUNCTIONS --------------

// Gets the location of the current tile.
void shmac_get_tile_loc(int * x, int * y);

// -------------- DEBUG FUNCTIONS --------------

// Prints a message over the serial port.
// This function recognizes the following arguments:
// 	%x = prints a 32-bit hexadecimal number
//	%s = prints a string
//	%c = prints a character
void shmac_printf(const char * format, ...);

// Prints a character to the serial port.
void shmac_print_char(char c);
// Prints a decimal number to the serial port:
void shmac_print_decimal(int n);
// Prints a string to the serial port.
void shmac_print_string(const char * string);
// Prints a hexadecimal number to the serial port.
void shmac_print_hex(uint32_t value);


#endif


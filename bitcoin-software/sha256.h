// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#ifndef SHA256_H
#define SHA256_H

#include <stdint.h>
#include "shmac.h"

// Base address of the SHA256 accelerator:
#define SHA256_BASE	((volatile void *) SHMAC_TILE_BASE + 0x3000)

// SHA256 register names and offsets:
#define SHA256_CTRL		0x000
#define SHA256_STATUS		0x000
#define SHA256_INPUT(x)		((0x08 + (x << 2)) >> 2)
#define SHA256_OUTPUT(x)	((0x48 + (x << 2)) >> 2)

// SHA256 control register bitnames:
#define SHA256_CTRL_ENABLE	0
#define SHA256_CTRL_UPDATE	1
#define SHA256_CTRL_RESET	2

// SHA256 status register bitnames:
#define SHA256_STATUS_READY	0
#define SHA256_STATUS_UPDATE	1
#define SHA256_STATUS_RESET	2
#define SHA256_STATUS_ENABLED	3

// Resets the SHA256 accelerator.
void sha256_reset(void);

// Retrieves the hash from the accelerator.
void sha256_get_hash(uint8_t * hash);

// Converts a hash into a printable C string.
// Note that the output argument should be preallocated with enough space for
// a terminating NULL character.
void sha256_format_hash(const uint8_t * hash, char * output);

#endif


// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#ifndef SHA256_H
#define SHA256_H

#include <stdint.h>
#include "shmac.h"

// Set to 1 to use hardware acceleration:
#ifndef SHA256_USE_HARDWARE
#define SHA256_USE_HARDWARE	1
#endif

// Base address of the hardware module:
#define SHA256_ACC_BASE	((volatile void *) SHMAC_TILE_BASE + 0x3000)

// SHA256 register names and offsets:
#define SHA256_CTRL		0x000
#define SHA256_STATUS		0x000
#define SHA256_INPUT(x)		((0x08 + (x << 2)) >> 2)
#define SHA256_OUTPUT(x)	((0x48 + (x << 2)) >> 2)

// SHA256 control register bitnames:
#define SHA256_CTRL_ENABLE	0
#define SHA256_CTRL_UPDATE	1
#define SHA256_CTRL_RESET	2
#define SHA256_CTRL_IRQCLR	3

// SHA256 status register bitnames:
#define SHA256_STATUS_READY	0
#define SHA256_STATUS_UPDATE	1
#define SHA256_STATUS_RESET	2
#define SHA256_STATUS_ENABLED	3

struct sha256_context;

// Creates a new SHA256 context:
struct sha256_context * sha256_new(void);
// Frees a SHA256 context:
void sha256_free(struct sha256_context *);

// Resets a SHA256 context:
void sha256_reset(struct sha256_context * ctx);

// Hash a block of data:
void sha256_hash_block(struct sha256_context * ctx, const uint32_t * data);

// Hashes a hash:
void sha256_hash_hash(struct sha256_context * ctx, const uint8_t * hash);

// Pad a block of data to hash:
void sha256_pad_le_block(uint8_t * block, int block_length, uint64_t total_length);

// Get the hash from a SHA256 context:
void sha256_get_hash(const struct sha256_context * ctx, uint8_t * hash);

// Formats a hash for printing:
void sha256_format_hash(const uint8_t * hash, char * output);

#endif


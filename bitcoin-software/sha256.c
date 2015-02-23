// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include "sha256.h"

static volatile uint32_t * module = SHA256_BASE;

void sha256_reset(void)
{
	// Toggle the reset bit in the control register to reset the module:
	module[SHA256_CTRL] = 1 << SHA256_CTRL_ENABLE | 1 << SHA256_CTRL_RESET;
	module[SHA256_CTRL] = 1 << SHA256_CTRL_ENABLE;
}

void sha256_get_hash(uint8_t * hash)
{
	for(int i = 0; i < 8; ++i)
	{
		uint32_t value = module[SHA256_OUTPUT(i)];
		hash[i * 4 + 0] = (value >> 24) & 0xff;
		hash[i * 4 + 1] = (value >> 16) & 0xff;
		hash[i * 4 + 2] = (value >>  8) & 0xff;
		hash[i * 4 + 3] = (value >>  0) & 0xff;
	}
}

void sha256_format_hash(const uint8_t * hash, char * output)
{
	static const char * hex_digits = "0123456789abcdef";
	for(int i = 0; i < 32; ++i)
	{
		uint8_t h = hash[i];

		output[i * 2 + 0] = hex_digits[(h >> 4) & 0xf];
		output[i * 2 + 1] = hex_digits[h & 0xf];
	}

	output[64] = 0;
}


// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include <stdint.h>

#include "enonce2.h"
#include "mm.h"
#include "shmac.h"

extern int sprintf(char * str, const char * format, ...);

struct enonce2
{
	uint32_t value;
};

struct enonce2 * enonce2_new(int length)
{
	struct enonce2 * retval = mm_allocate(sizeof(struct enonce2));

	if(length != 4)
		shmac_printf("STAT extranonce 2 length is not 4, miner will give wrong results!\n");

	retval->value = 0;
	return retval;
}

char * enonce2_tostring(const struct enonce2 * n)
{
	static const char * hex_digits = "0123456789abcdef";
	char * retval = mm_allocate(9);

	for(int i = 0; i < 4; ++i)
	{
		uint8_t byte = ((uint8_t *) &n->value)[i];
		retval[i * 2 + 0] = hex_digits[(byte >> 4) & 0xf];
		retval[i * 2 + 1] = hex_digits[(byte >> 0) & 0xf];
	}

	retval[8] = 0;
	return retval;
}


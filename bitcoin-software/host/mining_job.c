// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include <stdlib.h>
#include <string.h>

#include "mining_job.h"

struct mining_job * mining_job_new(char * job_id, char * prevhash, char * coinbase1,
	char * coinbase2, char ** merkle_branches, int num_merkle_branches,
	char * extranonce1, int extranonce2_length, uint32_t version, uint32_t nbits, uint32_t ntime)
{
	struct mining_job * retval = malloc(sizeof(struct mining_job));
	retval->job_id = strdup(job_id);
	retval->prevhash = strdup(prevhash);
	retval->coinbase1 = strdup(coinbase1);
	retval->coinbase2 = strdup(coinbase2);
	
	return retval;
}



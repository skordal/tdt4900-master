// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#ifndef MINING_JOB_H
#define MINING_JOB_H

#include <stdint.h>

struct mining_job
{
	char * job_id;
	char * prevhash;
	char * coinbase1, * coinbase2;
	char * extranonce1;
	int extranonce2_length;
	char * merkle_root;
	uint32_t version, nbits, ntime;
};

struct mining_job * mining_job_new(char * job_id, char * prevhash, char * coinbase1,
	char * coinbase2, char ** merkle_branches, int num_merkle_branches,
	char * extranonce1, int extranonce2_length, uint32_t version, uint32_t nbits, uint32_t ntime);

#endif


// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#ifndef WORKER_H
#define WORKER_H

#include <stdbool.h>

#include "enonce2.h"
#include "sha256.h"

#define WORKER_DELAY_CYCLES 50

// Structure containing all data neccessary for a worker CPU to do work.
struct worker
{
	int id;

	struct
	{
		char * coinb1;
		char * coinb2;
		char * extranonce1;
		char * version;
		char * nbits;
		char * ntime;
		struct enonce2 * extranonce2, * extranonce2_max;
	} job;

	struct
	{
		struct sha256_context * context;
		uint32_t nonce;
		uint8_t * coinbase;
	} state;

	struct
	{
		int hashes_per_second;
		bool running;
	} status;
	struct
	{
		bool running;
	} command;
};

// Initializes a worker context:
void worker_initialize(volatile struct worker * context, int id);

// Runs the worker:
void worker_run(volatile struct worker * context) __attribute((noreturn));

#endif


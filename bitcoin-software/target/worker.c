// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include <string.h>

#include "mm.h"
#include "shmac.h"
#include "worker.h"

static void create_coinbase(volatile struct worker * context);
static void hash_coinbase(volatile struct worker * context);

void worker_initialize(volatile struct worker * context, int id)
{
	context->status.running = false;
	context->status.hashes_per_second = 0;
	context->command.running = false;
	context->id = id;

	shmac_printf("STAT Initializing worker %d\n", id);
}

void worker_run(volatile struct worker * context)
{
	bool message_printed = false;

	while(true)
	{
		if(!message_printed)
		{
			shmac_printf("STAT Worker %d started!\n", context->id);
			message_printed = true;
		}

		if(context->command.running != context->status.running)
		{
			if(context->command.running) // Start a new hashing job:
			{
				context->state.nonce = 0;
				create_coinbase(context);

				// Hash the coinbase transaction:
			}
			context->status.running = context->command.running;
		}

		// Dummy work loop:
		for(int i = 0; i < 1000000; ++i)
			asm volatile("nop\n");

		if(context->status.running)
			++context->status.hashes_per_second;
		else
			context->status.hashes_per_second = 0;
	}
}

static void create_coinbase(volatile struct worker * context)
{
	char * extranonce2_string = enonce2_tostring(context->job.extranonce2);
	if(context->state.coinbase != 0)
		mm_free(context->state.coinbase);
	context->state.coinbase = mm_allocate(strlen(context->job.coinb1)
		+ strlen(context->job.extranonce1)
		+ strlen(extranonce2_string)
		+ strlen(context->job.coinb2) + 1);
	shmac_printf("C\n");
	int i = 0;

	for(int c = 0; c < strlen(context->job.coinb1); ++c, ++i)
		context->state.coinbase[i] = context->job.coinb1[c];
	for(int c = 0; c < strlen(context->job.extranonce1); ++c, ++i)
		context->state.coinbase[i] = context->job.extranonce1[c];
	for(int c = 0; c < strlen(extranonce2_string); ++c, ++i)
		context->state.coinbase[i] = extranonce2_string[c];
	for(int c = 0; c < strlen(context->job.coinb2); ++c, ++i)
		context->state.coinbase[i] = context->job.coinb2[c];
	context->state.coinbase[i] = 0;

	shmac_printf("STAT coinbase transaction = \"%s\"\n", context->state.coinbase);

	mm_free(extranonce2_string);
}

static void hash_coinbase(volatile struct worker * context)
{

}


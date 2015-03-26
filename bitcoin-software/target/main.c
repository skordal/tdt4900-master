// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#include "enonce2.h"
#include "irq.h"
#include "mm.h"
#include "sha256.h"
#include "shmac.h"
#include "worker.h"

// Worker thread structures:
static volatile struct worker * workers;

// Bitcoin mining data:
static char * job_id;
static char * prevhash;
static char * extranonce1;
static char * coinbase1, * coinbase2;
static char ** merkle_branches;
static int num_merkle_branches;
static int current_merkle_branch;
static int extranonce2_length;

// Variables for processing commands from the host:
static char command_buffer[256];
static int command_buffer_end = 0;

static void process_command(void);

void serial_irq_handler(int unused __attribute((unused)))
{
	char c = shmac_getc();
	shmac_printf("%c", c);

	if(c == '\n' || c == '\r')
	{
		command_buffer[command_buffer_end] = 0;
		process_command();

		command_buffer[0] = 0;
		command_buffer_end = 0;
	} else {
		command_buffer[command_buffer_end++] = c;
	}
}

void main(void)
{
#if 0
	shmac_printf("Hello!\n");
	struct sha256_context * ctx = sha256_new();
	sha256_reset(ctx);

	uint8_t block[64] = {'h', 'e', 'l', 'l', 'o'};
	uint8_t hash[32];
	sha256_pad_le_block(block, 5, 5);
	sha256_hash_block(ctx, block);
	sha256_get_hash(ctx, hash);

	sha256_reset(ctx);
	sha256_hash_hash(ctx, hash);
	sha256_get_hash(ctx, hash);

	char hash_string[65];
	sha256_format_hash(hash, hash_string);
	shmac_printf("%s\n", hash_string);
#endif
	if(shmac_get_tile_cpu_id() == 0)
	{
		// Allocate workers:
		workers = mm_allocate(sizeof(struct worker) * (shmac_get_cpu_count() - 1));
		for(int i = 0; i < shmac_get_cpu_count() - 1; ++i)
			worker_initialize(workers + i, i);

		command_buffer[0] = 0;
		irq_set_handler(1, serial_irq_handler);
		shmac_printf("STAT Hello world!\n");

		shmac_set_ready();
		shmac_printf("READY %d\n", shmac_get_cpu_count());
	} else {
		worker_run(&(workers[shmac_get_tile_cpu_id() - 1]));
		shmac_printf("STAT worker %d exited!\n", workers[shmac_get_tile_cpu_id() - 1].id);
	}

	while(1) asm volatile("nop"); // Burn cycles, use dat power
}

static void process_command(void)
{
	if(!strcmp(command_buffer, "HW")) // Send hardware information
	{
		// Send hardware information to the host;
		// For now, only the number of CPU tiles are sent.
		shmac_printf("HW %d\n", shmac_get_cpu_count());
	} else if(!strcmp(command_buffer, "PERF")) // Send performance information (H/s)
	{
		int hashes_per_second = 0;
		for(int i = 0; i < shmac_get_cpu_count() - 1; ++i)
			hashes_per_second += workers[i].status.hashes_per_second;
		shmac_printf("PERF %d\n", hashes_per_second);
	} else if(!strcmp(command_buffer, "RESET")) // Reset all hashing cores
	{
		// Stop all worker threads:
		for(int i = 0; i < shmac_get_cpu_count() - 1; ++i)
			workers[i].command.running = false;

		// Wait for all workers to stop:
		for(int i = 0; i < shmac_get_cpu_count() - 1; ++i)
			while(workers[i].status.running);

		shmac_printf("RESET\n");
	} else if(!strcmp(command_buffer, "UPDATE")) // Update work information for all workers
	{
		for(int i = 0; i < shmac_get_cpu_count() - 1; ++i)
		{
			workers[i].job.coinb1 = coinbase1;
			workers[i].job.coinb2 = coinbase2;
			workers[i].job.extranonce1 = extranonce1;
			workers[i].job.extranonce2 = enonce2_new(extranonce2_length);
		}
		shmac_printf("UPDATE\n");
	} else if(!strcmp(command_buffer, "START")) // Start mining workers
	{
		// Start all worker threads:
		for(int i = 0; i < shmac_get_cpu_count() - 1; ++i)
			workers[i].command.running = true;

		// Wait for all workers to start:
		for(int i = 0; i < shmac_get_cpu_count() - 1; ++i)
			while(!workers[i].status.running);

		shmac_printf("START\n");
	} else if(strlen(command_buffer) > 3 && !strncmp(command_buffer, "CB1", 3)) // Set coinbase 1
	{
		if(coinbase1 != 0)
			mm_free(coinbase1);
		coinbase1 = mm_allocate(strlen(command_buffer + 4) + 1);
		for(int i = 0; i < strlen(command_buffer + 4) + 1; ++i)
			coinbase1[i] = command_buffer[4 + i];
		shmac_printf("STAT Coinbase 1 set to %s\n", coinbase1);
	} else if(strlen(command_buffer) > 3 && !strncmp(command_buffer, "CB2", 3)) // Set coinbase 2
	{
		if(coinbase2 != 0)
			mm_free(coinbase2);
		coinbase2 = mm_allocate(strlen(command_buffer + 4) + 1);
		for(int i = 0; i < strlen(command_buffer + 4) + 1; ++i)
			coinbase2[i] = command_buffer[4 + i];
		shmac_printf("STAT Coinbase 2 set to %s\n", coinbase1);
	} else if(strlen(command_buffer) > 3 && !strncmp(command_buffer, "NMB", 3)) // Set number of merkle branches
	{
		// Free previously allocated merkle branches:
		if(merkle_branches != 0)
		{
			for(int i = 0; i < num_merkle_branches; ++i)
			{
				if(merkle_branches[i] != 0)
					mm_free(merkle_branches[i]);
			}

			mm_free(merkle_branches);
		}

		num_merkle_branches = atoi(command_buffer + 4);
		current_merkle_branch = 0;

		// Allocate room for the specified number of merkle branches:
		if(merkle_branches != 0)
			merkle_branches = mm_allocate(sizeof(char *) * num_merkle_branches);

		shmac_printf("STAT Number of merkle branches set to %d\n", num_merkle_branches);
	} else if(strlen(command_buffer) > 2 && !strncmp(command_buffer, "MB", 2)) // Set the next merkle branch value
	{
		char * merkle_branch = mm_allocate(strlen(command_buffer + 3) + 1);
		for(int i = 0; i < strlen(command_buffer + 3) + 1; ++i)
			merkle_branch[i] = command_buffer[3 + i];
		merkle_branches[current_merkle_branch++] = merkle_branch;
		shmac_printf("STAT Merkle branch received, %s\n", merkle_branch);
	} else if(strlen(command_buffer) > 3 && !strncmp(command_buffer, "EN1", 3)) // Set extranonce 1
	{
		if(extranonce1 != 0)
			mm_free(extranonce1);
		extranonce1 = mm_allocate(strlen(command_buffer + 4) + 1);
		for(int i = 0; i < strlen(command_buffer + 4) + 1; ++i)
			extranonce1[i] = command_buffer[4 + i];
		shmac_printf("STAT Extraonce 1 set to %s\n", extranonce1);
	} else if(strlen(command_buffer) > 4 && !strncmp(command_buffer, "EN2L", 4)) // Set extranonce 2 length
	{
		extranonce2_length = atoi(command_buffer + 5);
		shmac_printf("STAT Extranonce 2 length set to %d\n", extranonce2_length);
	} else if(strlen(command_buffer) > 3 && !strncmp(command_buffer, "JID", 3)) // Set job ID
	{
		if(job_id != 0)
			mm_free(job_id);
		job_id = mm_allocate(strlen(command_buffer + 4) + 1);
		for(int i = 0; i < strlen(command_buffer + 4) + 1; ++i)
			job_id[i] = command_buffer[4 + i];
		shmac_printf("STAT Job ID set to %s @ %x\n", command_buffer + 4, job_id);
	} else if(strlen(command_buffer) > 2 && !strncmp(command_buffer, "PH", 2)) // Set prevhash
	{
		if(prevhash != 0)
			mm_free(prevhash);
		prevhash = mm_allocate(strlen(command_buffer + 3) + 1);
		for(int i = 0; i < strlen(command_buffer + 3) + 1; ++i)
			prevhash[i] = command_buffer[3 + i];
		shmac_printf("STAT Prevhash set to %s\n", prevhash);
	} else{
		shmac_printf("STAT Unrecognized command: %s\n", command_buffer);
	}
}


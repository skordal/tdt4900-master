// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#include "irq.h"
#include "mm.h"
#include "mutex.h"
#include "sha256.h"
#include "shmac.h"
#include "timer.h"

#define BENCHMARK_PASSES	1

static volatile int * stats = (volatile void *) 0xf8000060;
static void benchmark_process(int cpu);
static void print_stats(void * unused);

void main(void)
{
	if(shmac_get_tile_cpu_id() == 0)
	{
		// Allocate statistics structure:
	//	stats = mm_allocate(sizeof(int) * shmac_get_cpu_count());
		for(int i = 0; i < shmac_get_cpu_count(); ++i)
			stats[i] = 0;

		shmac_printf("READY %d/%d\n", shmac_get_tile_cpu_id(),
			shmac_get_cpu_count());
		timer_start(0, 48828, TIMER_SCALE_1, true, print_stats, NULL);
		shmac_set_ready();
	}

	benchmark_process(shmac_get_tile_cpu_id());
	while(1) asm volatile("nop\n"); // Burn cycles, use dat power
}

static void benchmark_process(int cpu)
{
#if BENCHMARK_PASSES == 1
//	shmac_printf("Hashing started for CPU %d\n", cpu);

	struct sha256_context * ctx = sha256_new();
	uint8_t block[64] = {'a', 'b', 'c'};
	uint8_t hash[32];

	sha256_pad_le_block(block, 3, 3);

	while(1)
	{
		sha256_reset(ctx);
		sha256_hash_block(ctx, (uint32_t *) block);
		sha256_get_hash(ctx, hash);
		++stats[cpu];
	}
#else
	shmac_printf("Hashing started for CPU %d\n", cpu);

	struct sha256_context * ctx = sha256_new();
	uint8_t block[64] = {'a', 'b', 'c'};
	uint8_t hash[32];

	sha256_pad_le_block(block, 3, 3);

	while(1)
	{
		sha256_reset(ctx);
		sha256_hash_block(ctx, (uint32_t *) block);
		sha256_get_hash(ctx, hash);

		sha256_reset(ctx);
		sha256_hash_hash(ctx, hash);
		sha256_get_hash(ctx, hash);

		++stats[cpu];
	}
#endif
}

static void print_stats(void * unused)
{
	static int counter = 0;

	if(counter < 4)
		++counter;
	else {
		int hps = 0;
		for(int i = 0; i < shmac_get_cpu_count(); ++i)
		{
			hps += stats[i];
			shmac_printf("%d ", stats[i]);
			stats[i] = 0;
		}
		shmac_printf("\n");

		shmac_printf("%d H/s\n", hps);
		counter = 0;
	}
}


// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#include "bram.h"
#include "dma.h"
#include "irq.h"
#include "mm.h"
#include "mutex.h"
#include "sha256.h"
#include "shmac.h"
#include "timer.h"

#ifndef ENABLE_NUM_CORES
#define ENABLE_NUM_CORES	20000
#endif

#ifndef BENCHMARK_PASSES
#define BENCHMARK_PASSES	1
#endif

static volatile unsigned int * stats; //= (volatile void *) 0xf8000060;
static unsigned int * previous_stats;
static void benchmark_process(int cpu);
static void print_stats(void * unused);

#ifdef USE_INTERRUPTS
static uint8_t global_block[64] = {'a', 'b', 'c'};
static uint8_t ** buffers;
static struct sha256_context * contexts;
static bool * state;
#endif

#ifdef USE_INTERRUPTS
static void hash_handler(int unused)
{
	sha256_get_hash(&contexts[shmac_get_tile_cpu_id()], buffers[shmac_get_tile_cpu_id()]);

#if BENCHMARK_PASSES == 2
	if(state[shmac_get_tile_cpu_id()] == 0)
	{
#else
		++stats[shmac_get_tile_cpu_id()];

#endif
		sha256_reset(&contexts[shmac_get_tile_cpu_id()]);
		sha256_hash_block(&contexts[shmac_get_tile_cpu_id()], (uint32_t *) global_block);
#if BENCHMARK_PASSES == 2
	} else {
		++stats[shmac_get_tile_cpu_id()];
		sha256_reset(&contexts[shmac_get_tile_cpu_id()]);
		sha256_hash_hash(&contexts[shmac_get_tile_cpu_id()], buffers[shmac_get_tile_cpu_id()]);
	}
#endif // BENCHMARK_PASSES == 2
}
#endif // USE_INTERRUPTS

void main(void)
{
	if(shmac_get_tile_cpu_id() == 0)
	{
		// Allocate statistics structures:
		stats = bram_allocate(1, shmac_get_cpu_count() * sizeof(unsigned int));
		previous_stats = mm_allocate(sizeof(int) * shmac_get_cpu_count());
		for(int i = 0; i < shmac_get_cpu_count(); ++i)
		{
			stats[i] = 0;
			previous_stats[i] = 0;
		}

#ifdef USE_INTERRUPTS
		contexts = (void *) bram_allocate(0, shmac_get_cpu_count() * sizeof(struct sha256_context));//(stats + shmac_get_cpu_count());
		for(int i = 0; i < shmac_get_cpu_count(); ++i)
			contexts[i].accelerated = 1;

		buffers = (void *) bram_allocate(0, shmac_get_cpu_count() * sizeof(uint32_t));//(contexts + shmac_get_cpu_count());
		for(int i = 0; i < shmac_get_cpu_count(); ++i)
		{
			buffers[i] = bram_allocate(0, 32);//(void *) ((unsigned int) (buffers + shmac_get_cpu_count())
				//+ (unsigned int) (64 * i));
		}

		state = bram_allocate(0, shmac_get_cpu_count() * sizeof(bool));
		for(int i = 0; i < shmac_get_cpu_count(); ++i)
			state[i] = 0;

		sha256_pad_le_block(global_block, 3, 3);
#endif

		shmac_printf("READY %d\n", shmac_get_cpu_count());
		timer_start(0, 48828, TIMER_SCALE_1, true, print_stats, NULL);
		shmac_set_ready();
	}

	if(shmac_get_tile_cpu_id() < ENABLE_NUM_CORES)
	{
#ifdef USE_INTERRUPTS
		sha256_reset(&contexts[shmac_get_tile_cpu_id()]);
		irq_set_handler(5, hash_handler);
#	ifdef USE_CACHES
		shmac_enable_caches();
#	endif
#else
#	ifdef USE_CACHES
		shmac_enable_caches();
#	endif
		benchmark_process(shmac_get_tile_cpu_id());
#endif
	}

#if 0
	// Do a simple DMA test:
	shmac_printf("Setting up DMA test...\n");
	for(int i = 0; i < 10; ++i)
		*((volatile uint32_t *) (0xf8000020 + (i * 4))) = i;
	dma_set_load_address0(0xf8000020);
	dma_set_store_address0(0xf8000060);
	dma_set_request_details0(9 << 20 | 1);

	while(!(dma_get_request_details0() & 4));
	shmac_printf("Finished!\n");

	for(int i = 0; i < 100; ++i)
		asm volatile("nop\n");

	for(int i = 0; i < 10; ++i)
		shmac_printf("%d ", *((volatile uint32_t *) (0xf8000060 + (i * 4))));
	shmac_printf("\n");
#endif

	while(1) asm volatile("nop\n"); // Burn cycles, use dat power
}

#ifndef USE_INTERRUPTS
static void benchmark_process(int cpu)
{
#if BENCHMARK_PASSES == 1
	//struct sha256_context * ctx = sha256_new();
	struct sha256_context ctx;
	ctx.accelerated = SHA256_USE_HARDWARE;
//	ctx.accelerated = 1;

	uint8_t block[64] = {'a', 'b', 'c'};
	uint8_t hash[32];

	sha256_pad_le_block(block, 3, 3);

	while(1)
	{
		sha256_reset(&ctx);
		sha256_hash_block(&ctx, (uint32_t *) block);
		sha256_get_hash(&ctx, hash);
		++stats[cpu];
	}
#elif BENCHMARK_PASSES == 2
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
#else
#	error "BENCHMARK_PASSES can only be 1 or 2!"
#endif
}
#endif

static void print_stats(void * unused)
{
	static int counter = 0;

	if(counter < 4)
		++counter;
	else {
		unsigned int hps = 0;
		for(int i = 0; i < shmac_get_cpu_count(); ++i)
		{
			unsigned int n = stats[i], p;
			if(previous_stats[i] < n)
				p = n - previous_stats[i];
			else
				p = (0 - previous_stats[i]) + n;
			hps += p;
//			hps += stats[i];
			shmac_printf("%d ", p);
//			stats[i] = 0;
			previous_stats[i] = n;
		}
		shmac_printf("\n");

		shmac_printf("%d H/s\n", hps);
		counter = 0;
	}
}


// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include "mutex.h"

#if !defined(USE_CLASSIC_MUTEXES) && !defined(USE_IMPROVED_MUTEXES)
#warning "No mutex implementation selected!"
#endif

static mutex_t * next_mutex = (volatile void *) 0xf8000000;

void mutex_initialize(void)
{
}

mutex_t * mutex_new(void)
{
	mutex_t * retval = next_mutex++;
	*retval = MUTEX_INITIALIZER;

	return retval;
}

void mutex_lock(mutex_t * mutex)
{
#ifdef USE_IMPROVED_MUTEXES
	asm volatile(
		// Set the initial wait delay:
		"	mov v3, %[delay]\n"

		// Attempt to lock the mutex:
		"lock:\n"
		"	mov v2, #1\n"
		"	swp v1, v2, [%[mutex]]\n"
		"	cmp v1, v2\n"
		"	bne success\n"

		// If the mutex could not be locked, wait a short amount of
		// time before trying again:
		"	mov v1, v3\n"
		"delay_loop:\n"
		"	subs v1, #1\n"
		"	bne delay_loop\n"

		// Increase the delay if the next lock does not succeed:
		"	adds v3, v3\n"
		"	moveq v3, %[delay]\n"

		// Retry:
		"	b lock\n"

		// If locking is successful, the code jumps here:
		"success:\n"
		: [mutex] "+r" (mutex)
		: [delay] "I" (1)
		: "v1", "v2", "v3", "memory", "cc"
	);
#elif defined(USE_CLASSIC_MUTEXES)
	__asm__ (

		// save R4
		"push {r4}\n"

		// init delay between lock attempts
		"MOV r4, #1\n"

		// try lock and finish if successful
		"lock:\n"
		"MOV r2, #1\n"
		"SWP r1, r2, [r0]\n"
		"CMP r1, r2\n"
		"BNE locked\n"

		// load delay and wait in a loop
		"MOV r3, r4\n"
		"wait:\n"
		"SUB r3, #1\n"
		"CMP r3, #0\n"
		"BNE wait\n"

		// double delay or load 1 if overflown
		"ADD r4, r4\n"
		"CMP r4, #0\n"
		"MOVEQ r4, #1\n"

		// repeat lock attempt
		"B lock\n"

		"locked:\n"

		// restore R4
		"pop {r4}\n"
	);
#endif
}

bool mutex_trylock(mutex_t * mutex)
{
	bool retval = false;
	asm volatile(
		"	mov v2, #1\n"
		"	swp v1, v2, [%[mutex]]\n"
		"	add v1, #1\n"
		"	and %[retval], v1, #1\n"
		: [retval] "=r" (retval), [mutex] "+r" (mutex)
		:: "v1", "v2", "memory"
	);

	return retval;
}

void mutex_unlock(mutex_t * mutex)
{
#ifdef USE_IMPROVED_MUTEXES
	asm volatile(
		"mov v2, #0\n"
		"swp v1, v2, [%[mutex]]\n"
		: [mutex] "+r" (mutex)
		:: "v1", "v2", "memory"
	);
#elif defined(USE_CLASSIC_MUTEXES)
	__asm__ (
		"MOV r2, #0\n"
		"SWP r1, r2, [r0]\n"
	);
#endif
}


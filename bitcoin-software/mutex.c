// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include "mutex.h"

void mutex_initialize(mutex_t * mutex)
{
	*mutex = MUTEX_INITIALIZER;
}

// Code below originally from the mutex code in the software/benchmarks/common
// directory of the SHMAC repository.

void mutex_lock(mutex_t * mutex)
{
	asm volatile(
		// Set the initial wait delay:
		"	mov v3, %[delay]\n"

		// Attempt to lock the mutex:
		"lock:\n"
		"	mov v2, #1\n"
		"	swp v2, v1, [%[mutex]]\n"
		"	cmp v2, v1\n"
		"	bne success\n"

		// If the mutex could not be locked, wait a short amount of
		// time before trying again:
		"	mov v1, v3\n"
		"delay_loop:\n"
		"	subs v1, #1\n"
		"	bne delay_loop\n"

		// Increase the delay if the next lock does not succeed:
		"	adds v3, %[delay]\n"
		"	movcs v3, #1\n"

		// Retry:
		"	b lock\n"

		// If locking is successful, the code jumps here:
		"success:\n"
		: [mutex] "+r" (mutex)
		: [delay] "I" (1)
		: "v1", "v2", "v3", "memory", "cc"
	);
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
	asm volatile(
		"mov v2, #0\n"
		"swp v1, v2, [%[mutex]]\n"
		: [mutex] "+r" (mutex)
		:: "v1", "v2", "memory"
	);
}


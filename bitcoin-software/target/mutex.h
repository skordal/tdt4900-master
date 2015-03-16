// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#ifndef MUTEX_H
#define MUTEX_H

#include <stdbool.h>

#define MUTEX_INITIALIZER	0

// Use the defines below to choose a mutex implementation to use;
// the "classic" mutexes are
//#define USE_CLASSIC_MUTEXES	1
//#define USE_IMPROVED_MUTEXES	1

// This mutex module is based on the previous mutex code already found in the
// SHMAC repo under software/shmac_test_* and software/benchmarks.

typedef volatile int mutex_t;

// Allocates a new mutex. Mutexes cannot be freed, so make sure your really need one.
mutex_t * mutex_new(void);

// Attempts to lock a mutex, enters a busy-wait loop until it succeeds:
void mutex_lock(mutex_t * mutex);

// Attempts to lock a mutex, returns whether it succeeded:
bool mutex_trylock(mutex_t * mutex);

// Unlocks a mutex:
void mutex_unlock(mutex_t * mutex);

#endif


// The Mordax Microkernel
// (c) Kristian Klomsten Skordal 2013 <kristian.skordal@gmail.com>
// Report bugs and issues on <http://github.com/skordal/mordax/issues>

#ifndef MORDAX_MM_H
#define MORDAX_MM_H

#include <stdbool.h>
#include <stdint.h>

/** Initializes the memory manager. */
void mm_initialize(void);

/** Prints a list of all the memory blocks currently allocated (both used and unused). */
void print_blocks(void);

/**
 * Allocates an area of kernel memory.
 * @param size size of the area to allocate.
 * @param alignment alignment of the start of the memory area.
 * @param flags additional properties of the memory area.
 * @return the allocated memory area or `NULL` if no memory was available.
 */
void * mm_allocate(unsigned int size) __attribute((malloc));

/**
 * Frees an area of kernel memory. Null pointers can be freed, in which case
 * no action is taken.
 * @param area the area of memory to free.
 */
void mm_free(void * area);

#endif


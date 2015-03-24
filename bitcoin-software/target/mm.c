// The Mordax Microkernel
// (c) Kristian Klomsten Skordal 2013 <kristian.skordal@gmail.com>
// Report bugs and issues on <http://github.com/skordal/mordax/issues>

#include "mm.h"
#include "mutex.h"
#include "shmac.h"

#ifndef MINIMUM_BLOCK_SIZE
#define MINIMUM_BLOCK_SIZE	4
#endif

// Virtual memory block:
struct memory_block
{
	unsigned int size;
	void * start;
	bool used;
	struct memory_block * next, * prev;
};

// Imported from the linker script:
extern void * __bss_end;
extern void * __dataspace_end;

// Memory manager mutex:
static mutex_t * mutex;

// Head of the list of memory blocks:
struct memory_block * memory_list = (void *) &__bss_end;

// Total amount of free memory:
static unsigned int total_free_memory = 0;

// Splits a block at the specified offset:
static struct memory_block * mm_split(struct memory_block *, unsigned offset);

void print_blocks(void)
{
	struct memory_block * current= memory_list;
	while(current != 0)
	{
		shmac_printf("Block @ %p\n\r", current);
		shmac_printf("\tstart: %p\n\r", current->start);
		shmac_printf("\tnext: %p\n\r", current->next);
		shmac_printf("\tprev: %p\n\r", current->prev);
		shmac_printf("\tsize: %d\n\r", (unsigned int) current->size);
		shmac_printf("\tused: %s\n\r", current->used ? "true" : "false");

		current = current->next;
	}
}

void mm_initialize(void)
{
	if(shmac_get_tile_cpu_id() == 0)
	{
		mutex = mutex_new();

		struct memory_block * first_block = memory_list;
		for(int i = 0; i < sizeof(struct memory_block); ++i)
		{
			char * temp = (char *) first_block;
			temp[i] = 0;
		}

		first_block->start = (void *) ((uint32_t) memory_list + sizeof(struct memory_block));
		first_block->size = ((uint32_t) &__dataspace_end - (uint32_t) &__bss_end - sizeof(struct memory_block));
		total_free_memory = first_block->size;
	}
}

void * mm_allocate(unsigned int size)
{
	unsigned int alignment = 4;
	void * retval = 0;

	if(size < MINIMUM_BLOCK_SIZE)
		size = MINIMUM_BLOCK_SIZE;
	size += 3;
	size &= -4;

	while(total_free_memory <= size)
		return 0;

	mutex_lock(mutex);

	struct memory_block * current = memory_list;
	do {
		if(current->size >= size && !current->used)
		{
			uint32_t block_address = (uint32_t) current->start;
			uint32_t offset = ((block_address + alignment - 1) & -alignment) - block_address;

			if(offset == 0)
			{
				if(current->size > size)
					mm_split(current, size);

				current->used = true;
				total_free_memory -= current->size;
				retval = current->start;
				break;
			} else if(current->size - (offset + sizeof(struct memory_block)) >= size
				&& offset >= sizeof(struct memory_block) + MINIMUM_BLOCK_SIZE)
			{
				struct memory_block * split_block = mm_split(current, offset - sizeof(struct memory_block));
				if(split_block != 0)
				{
					if(split_block->size > size)
						mm_split(split_block, size);

					split_block->used = true;
					total_free_memory -= split_block->size;
					retval = split_block->start;
					break;
				}
			}
		}

		current = current->next;
	} while(current != 0);

	mutex_unlock(mutex);
	return retval;
}

void mm_free(void * area)
{
	struct memory_block * block = (void *) ((uint32_t) area - sizeof(struct memory_block));

	mutex_lock(mutex);

	block->used = false;
	total_free_memory += block->size;

	if(block->prev != 0 && !block->prev->used)
	{
		block->prev->size += block->size + sizeof(struct memory_block);
		total_free_memory += sizeof(struct memory_block);

		block->prev->next = block->next;
		if(block->next)
			block->next->prev = block->prev;
		block = block->prev;
	}

	if(block->next != 0 && !block->next->used)
	{
		block->size += block->next->size + sizeof(struct memory_block);
		total_free_memory += sizeof(struct memory_block);

		if(block->next->next)
			block->next->next->prev = block;
		block->next = block->next->next;
	}

	mutex_unlock(mutex);
}

static struct memory_block * mm_split(struct memory_block * block, unsigned offset)
{
	if(block->size <= offset + sizeof(struct memory_block) + MINIMUM_BLOCK_SIZE)
		return 0;

	unsigned int new_block_size = block->size - (offset + sizeof(struct memory_block));
	if(new_block_size >= MINIMUM_BLOCK_SIZE)
	{
		struct memory_block * retval = (struct memory_block *) ((uint32_t) block->start + offset);

		retval->size = new_block_size;
		retval->start = (void *) ((uint32_t) retval + sizeof(struct memory_block));
		retval->prev = block;
		retval->next = block->next;

		retval->used = false;

		if(block->next != 0)
			block->next->prev = retval;
		block->next = retval;
		block->size = offset;

		total_free_memory -= sizeof(struct memory_block);
		return retval;
	} else
		return 0;
}


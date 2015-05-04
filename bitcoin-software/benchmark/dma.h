// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#ifndef DMA
#define DMA

#include <stdint.h>
#include "shmac.h"

// Base address of the DMA Slave accelerator:
#define DMA_BASE	((volatile void *) SHMAC_TILE_BASE + 0x4000)

// Interrupt value of DMA Module
#define DMA_irq		6

// DMA register names and offsets:
#define DMA_SLAVE_LREG0		0x000
#define DMA_SLAVE_SREG0		(0x004 >> 2)
#define DMA_SLAVE_RREG0		(0x008 >> 2)
#define DMA_SLAVE_LREG1		(0x00c >> 2)
#define DMA_SLAVE_SREG1		(0x010 >> 2)
#define DMA_SLAVE_RREG1		(0x014 >> 2)

// SHA256 control register bitnames:
#define DMA_SLAVE_ENABLE	0

// Resets the DMA Module.
void dma_reset(void);

uint32_t dma_get_src_address0();
uint32_t dma_get_src_address1();
uint32_t dma_get_dest_address0();
uint32_t dma_get_dest_address1();
uint32_t dma_get_request_details0();
uint32_t dma_get_request_details1();

void dma_set_src_address0(uint32_t src);
void dma_set_src_address1(uint32_t src);
void dma_set_dest_address0(uint32_t dest);
void dma_set_dest_address1(uint32_t dest);
void dma_set_request_details0(uint32_t request);
void dma_set_request_details1(uint32_t request);

#endif


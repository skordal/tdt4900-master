// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include "dma.h"

static volatile uint32_t * module = DMA_BASE;

void dma_get_load_address0(uint8_t * load);
void dma_get_store_address0(uint8_t * store);
void dma_get_request_details0(uint8_t * request);
//void dma_get_load_address1(uint8_t * load);
//void dma_get_store_address1(uint8_t * store);
//void dma_get_request_details1(uint8_t * request);

// Sets the the starting load addresses, storing addresses, and request details (including on/off) from the dma slave.
void dma_set_load_address0(uint8_t * load);
void dma_set_store_address0(uint8_t * store);
void dma_set_request_details0(uint8_t * request);


// Gets
void dma_get_load_address0(uint8_t* load){
	for(int i = 0; i < 4; ++i)
	{
		uint32_t value = module[DMA_SLAVE_LREG0];
		load[0] = (value >> 24) & 0xff;
		load[1] = (value >> 16) & 0xff;
		load[2] = (value >>  8) & 0xff;
		load[3] = (value >>  0) & 0xff;
	}
}

void dma_get_store_address0(uint8_t* store){
	for(int i = 0; i < 4; ++i)
	{
		uint32_t value = module[DMA_SLAVE_SREG0];
		store[0] = (value >> 24) & 0xff;
		store[1] = (value >> 16) & 0xff;
		store[2] = (value >>  8) & 0xff;
		store[3] = (value >>  0) & 0xff;
	}
}

void dma_get_request_details0(uint8_t* request){
	for(int i = 0; i < 4; ++i)
	{
		uint32_t value = module[DMA_SLAVE_RREG0];
		request[0] = (value >> 24) & 0xff;
		request[1] = (value >> 16) & 0xff;
		request[2] = (value >>  8) & 0xff;
		request[3] = (value >>  0) & 0xff;
	}
}

// Sets

void dma_set_load_address0(uint8_t* load){
	
	uint32_t value = 24 << load[0] | 16 << load[1] | 8 << load[2] | 0 << load[3];
	module[DMA_SLAVE_LREG0] = value;
	
}

void dma_set_store_address0(uint8_t* store){
	
	uint32_t value = 24 << store[0] | 16 << store[1] | 8 << store[2] | 0 << store[3];
	module[DMA_SLAVE_SREG0] = value;
	
}

void dma_set_request_details0(uint8_t* request){
	
	uint32_t value = 24 << request[0] | 16 << request[1] | 8 << request[2] | 0 << request[3];
	module[DMA_SLAVE_RREG0] = value;
	
}
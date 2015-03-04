// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include "dma.h"

static volatile uint32_t * module = DMA_BASE;

void dma_reset(void);

void dma_get_load_address0(uint32_t * load);
void dma_get_store_address0(uint32_t * store);
void dma_get_request_details0(uint32_t * request);
//void dma_get_load_address1(uint32_t * load);
//void dma_get_store_address1(uint32_t * store);
//void dma_get_request_details1(uint32_t * request);

// Sets the the starting load addresses, storing addresses, and request details (including on/off) from the dma slave.
void dma_set_load_address0(uint32_t * load);
void dma_set_store_address0(uint32_t * store);
void dma_set_request_details0(uint32_t * request);

void dma_reset(void){
	//EMPTY
}

// Gets
void dma_get_load_address0(uint32_t* load){
	*load = module[DMA_SLAVE_LREG0];
}

void dma_get_store_address0(uint32_t* store){
	*store = module[DMA_SLAVE_SREG0];
}

void dma_get_request_details0(uint32_t* request){
	*request = module[DMA_SLAVE_RREG0]; 
}

// Sets

void dma_set_load_address0(uint32_t* load){
	module[DMA_SLAVE_LREG0] = *load;
}

void dma_set_store_address0(uint32_t* store){
	module[DMA_SLAVE_SREG0] = *store;
}

void dma_set_request_details0(uint32_t* request){
	module[DMA_SLAVE_RREG0] = *request;
}
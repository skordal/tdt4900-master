// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include "dma.h"

#include "shmac.h" //TODO: Remove when test is done

static volatile uint32_t * module = DMA_BASE;

void dma_reset(void);
uint32_t dma_get_src_address0();
uint32_t dma_get_src_address1();
uint32_t dma_get_dest_address0();
uint32_t dma_get_dest_address1();
uint32_t dma_get_request_details0();
uint32_t dma_get_request_details1();

// Sets the the starting source addresses, destination addresses, and request details (including on/off) from the dma slave.
void dma_set_src_address0(uint32_t src);
void dma_set_src_address1(uint32_t src);
void dma_set_dest_address0(uint32_t dest);
void dma_set_dest_address1(uint32_t dest);
void dma_set_request_details0(uint32_t request);
void dma_set_request_details1(uint32_t request);


void dma_reset(void){
	//EMPTY
}

//Getters
uint32_t dma_get_src_address0(){
	return module[DMA_SLAVE_LREG0];
}

uint32_t dma_get_src_address1(){
	return module[DMA_SLAVE_LREG1];
}

uint32_t dma_get_dest_address0(){
	return module[DMA_SLAVE_SREG0];
}

uint32_t dma_get_dest_address1(){
	return module[DMA_SLAVE_SREG1];
}

uint32_t dma_get_request_details0(){
	return module[DMA_SLAVE_RREG0]; 
}

uint32_t dma_get_request_details1(){
	return module[DMA_SLAVE_RREG1];
}

// Setters
void dma_set_src_address0(uint32_t src){
	module[DMA_SLAVE_LREG0] = src;
}

void dma_set_src_address1(uint32_t src){
	module[DMA_SLAVE_LREG1] = src;
}

void dma_set_dest_address0(uint32_t dest){
	module[DMA_SLAVE_SREG0] = dest;
}

void dma_set_dest_address1(uint32_t dest){
	module[DMA_SLAVE_SREG1] = dest;
}

void dma_set_request_details0(uint32_t request){
	module[DMA_SLAVE_RREG0] = request;
}

void dma_set_request_details1(uint32_t request){
	module[DMA_SLAVE_RREG1] = request;
}


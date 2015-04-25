// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include "dma.h"

#include "shmac.h" //TODO: Remove when test is done

static volatile uint32_t * module = DMA_BASE;

void dma_reset(void);
uint32_t dma_get_load_address0();
uint32_t dma_get_store_address0();
uint32_t dma_get_request_details0();

uint32_t dma_get_load_address1();
uint32_t dma_get_store_address1();
uint32_t dma_get_request_details1();

// Sets the the starting load addresses, storing addresses, and request details (including on/off) from the dma slave.
void dma_set_load_address0(uint32_t load);
void dma_set_store_address0(uint32_t store);
void dma_set_request_details0(uint32_t request);

void dma_set_load_address1(uint32_t load);
void dma_set_store_address1(uint32_t store);
void dma_set_request_details1(uint32_t request);




void dma_reset(void){
	//EMPTY
}

// Getters, channel 0
uint32_t dma_get_load_address0(){
	return module[DMA_SLAVE_LREG0];
}

uint32_t dma_get_store_address0(){
	return module[DMA_SLAVE_SREG0];
}

uint32_t dma_get_request_details0(){
	return module[DMA_SLAVE_RREG0]; 
}


// Getters, channel 1
uint32_t dma_get_load_address1(){
	return module[DMA_SLAVE_LREG1];
}

uint32_t dma_get_store_address1(){
	return module[DMA_SLAVE_SREG1];
}

uint32_t dma_get_request_details1(){
	return module[DMA_SLAVE_RREG1]; 
}


// Setters, channel 0

void dma_set_load_address0(uint32_t load){
	module[DMA_SLAVE_LREG0] = load;
}

void dma_set_store_address0(uint32_t store){
	module[DMA_SLAVE_SREG0] = store;
}

void dma_set_request_details0(uint32_t request){
	module[DMA_SLAVE_RREG0] = request;
}


// Setters, channel 1

void dma_set_load_address1(uint32_t load){
	module[DMA_SLAVE_LREG1] = load;
}

void dma_set_store_address1(uint32_t store){
	module[DMA_SLAVE_SREG1] = store;
}

void dma_set_request_details1(uint32_t request){
	module[DMA_SLAVE_RREG1] = request;
}


#if 0

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

// Gets
void dma_get_load_address0(uint32_t* load){
	// *load = module[DMA_SLAVE_LREG0];
	//int32_t * address = 0xfffe4000;
	// *load = *address;
	
	shmac_printf("Let's print a series of numbers for debugging:\n\r");
	shmac_printf("\n\r");
	shmac_printf("Module base address: %x\n\r", module);
	shmac_printf("DMA_SLAVE_LREG0: %x\n\r", DMA_SLAVE_LREG0);
	shmac_printf("DMA_SLAVE_SREG0: %x\n\r", DMA_SLAVE_SREG0);
	shmac_printf("DMA_SLAVE_RREG0: %x\n\r", DMA_SLAVE_RREG0);
	shmac_printf("\n\r");
	shmac_printf("&(module[DMA_SLAVE_LREG0]): %x\n\r", &(module[DMA_SLAVE_LREG0]));
	shmac_printf("&(module[DMA_SLAVE_SREG0]): %x\n\r", &(module[DMA_SLAVE_SREG0]));
	shmac_printf("&(module[DMA_SLAVE_RREG0]): %x\n\r", &(module[DMA_SLAVE_RREG0]));
	shmac_printf("\n\r");
	shmac_printf("module + DMA_SLAVE_LREG0: %x\n\r", module + DMA_SLAVE_LREG0);
	shmac_printf("module + DMA_SLAVE_SREG0: %x\n\r", module + DMA_SLAVE_SREG0);
	shmac_printf("module + DMA_SLAVE_RREG0: %x\n\r", module + DMA_SLAVE_RREG0);
	
	
	shmac_printf("Tdma_get_load_address0: LLREG0 Loaded. At address %x, value is %x\n\r", module + DMA_SLAVE_LREG0, module[DMA_SLAVE_LREG0]);
	return module[DMA_SLAVE_LREG0];
}
void dma_get_store_address0(uint32_t* store){
	*store = module[DMA_SLAVE_SREG0];
	//uint32_t * address = 0xfffe4004;
	//*store = *address;
}

void dma_get_request_details0(uint32_t* request){
	*request = module[DMA_SLAVE_RREG0]; 
	//uint32_t * address = 0xfffe4008;
	//*request = *address;
}

// Sets

void dma_set_load_address0(uint32_t* load){
	module[DMA_SLAVE_LREG0] = *load;
	//uint32_t * address = 0xfffe4000;
	//*address = *load;
}

void dma_set_store_address0(uint32_t* store){
	module[DMA_SLAVE_SREG0] = *store;
	//uint32_t * address = 0xfffe4004;
	//*address = *store;
}

void dma_set_request_details0(uint32_t* request){
	module[DMA_SLAVE_RREG0] = *request;
	//uint32_t * address = 0xfffe4008;
	//*address = *request;
}

#endif

void printDMADetails(){ //TODO: Remove when debug is over
	shmac_printf("DMA_BASE: %x, DMA_SLAVE_LREG0: %x, DMA_SLAVE_SREG0: %x, DMA_SLAVE_RREG0: %x\n\r", DMA_BASE, DMA_SLAVE_LREG0, DMA_SLAVE_SREG0, DMA_SLAVE_RREG0);
}

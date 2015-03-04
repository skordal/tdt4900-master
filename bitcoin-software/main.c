// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include <stdint.h>
#include <stdbool.h>

#include "irq.h"
#include "sha256.h"
#include "shmac.h"
#include "timer.h"

// The worker thread structures are statically allocated for now. Remember to
// update NUM_WORKERS to the correct number of worker CPUs (total number of CPUs
// minus one) in the Makefile when changing the hardware!

void timer_callback(void * data)
{
	shmac_printf("CPU%d: Ping!\n\r");
}



void main(void)
{
	if(shmac_get_tile_cpu_id() == 0)
	{
		shmac_initialize();
		shmac_printf("The Great and Awesome Heterogeneous Bitcoin Miner Project\n\r");
		shmac_printf("By Kristian K. Skordal and Torbjorn Langland\n\r\n\r");

//		shmac_set_ready();
	}

	shmac_printf("CPU%d: CPU %d of %d checking in!\n\r", shmac_get_tile_cpu_id(),
		shmac_get_tile_cpu_id() + 1, shmac_get_cpu_count());

	timer_start(0, 60000, TIMER_SCALE_1, true, timer_callback, 0); 

	shmac_printf("\n\rEnd programme.\n\r");
	while(1); // Burn cycles until Amber implements something like wfi
	*/
	
	// DMA Part:
	
	shmac_printf("THIS IS A CHAIR!!!\n");
	shmac_printf("THIS IS A CHAIR!!!\n");
	shmac_printf("THIS IS A CHAIR!!!\n");
	
	//shmac_printf("Resetting DMA Module (And I resent the use of ...)");
	/*dma_reset();
	//shmac_printf("ok\n\r");
	
	int data_count = 16; //Change this, depending on own taste
	uint32_t *load, *load_location, *load_test, *store, *store_location, *store_test, *request, *request_test;
	uint32_t data[data_count];
	uint32_t data_test[data_count];
	
	shmac_printf("Setting Load address: 0x1000 0000 \n");
	*load = 0x10000000;
	dma_set_load_address0(load);
	
	shmac_printf("Getting Load address:\n");
	dma_get_load_address0(load_test);
	shmac_printf("This is the load address gotten: %x\n", *load_test);
	
	shmac_printf("Setting Store address: 0x4000 0000 \n");
	*store = 0x20000000;
	dma_set_load_address0(load);
	
	shmac_printf("Getting Store address:\n");
	dma_get_store_address0(store_test);
	shmac_printf("This is the store address gotten: %x\n", *store_test);
	
	shmac_printf("Setting up raw data from loading addresses, with following square numbers: 1-4-9-16-25.... (16 in total)\n");
	
	uint32_t i;
	for(i =0; i<data_count; i++){
		data[i] = (i+1)*(i+1);	
	}
	
	load_location = (void*) 0x10000000;
	for(i =0; i<data_count; i++){
		load_location[i] = data[i];	 //TODO: I believe jumps should be 32 bytes per i, since i and the pointer load_location is of uint32_t. Change with i*4 if wrong 
	}
	
	shmac_printf("Activating DMA: Count: 16 (15 + start), Byte addressing high, ON high. Hex value: 0x00F8 0001\n");
	*request = 0x00F80001;
	
	dma_set_request_details0(request);
	
	bool on = true;
	int a;
	while(on){
		
		dma_get_request_details0(request_test); //TODO: Also test with much larger count if DMA is too fast
		
		if(request_test[3] == 0x00){
			shmac_printf("DMA transfer complete\n");
			on = false;
		} else {
			shmac_printf("DMA active. Run through giant for-loop\n");
			for(a = 0; 0<1000000000; a++){
				// A man walked into a bar. Ouch!
			}
		}
		
	}
	
	store_location = (void*) 0x20000000;
	for(i =0; i<data_count; i++){
		data_test[i] = store_location[i];	//TODO: I believe jumps should be 32 bytes per i, since i and the pointer load_location is of uint32_t. Change with i*4 if wrong 
	}
	
	shmac_printf("Now printing out data from old and new location\n");
	for(i=0; i<data_count; i++){
		shmac_printf("Old: %d, New: %d\n", data[i], data_test[i]);
	}
	
	shmac_printf("\n\rEnd programme.\n\r");*/
	while(1); // Burn cycles until Amber implements something like wfi

	shmac_printf("CPU%d: End of main.\n\r", shmac_get_tile_cpu_id());

}


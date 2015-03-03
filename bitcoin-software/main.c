// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include <stdint.h>

#include "sha256.h"
#include "shmac.h"
#include "dma.h"



void main(void)
{
	shmac_printf("The Great and Awesome Heterogeneous Bitcoin Miner Project\n\r");
	shmac_printf("By Kristian K. Skordal and Torbjorn Langland\n\r\n\r");

	int x, y;
	shmac_get_tile_loc(&x, &y);
	shmac_printf("Tile location: (%d, %d)\n\r\n\r", x, y);
	
	//Hashing module part
	/*
	shmac_printf("Resetting SHA256 accelerator... ");
	sha256_reset();
	shmac_printf("ok\n\r");

	uint8_t hash[32];
	char hash_string[65];

	sha256_get_hash(hash);
	sha256_format_hash(hash, hash_string);
	shmac_printf("Default/reset hash value: %s\n\r", hash_string);

	shmac_printf("\n\rEnd programme.\n\r");
	while(1); // Burn cycles until Amber implements something like wfi
	*/
	
	// DMA Part:
	
	//shmac_printf("Resetting DMA Module (And I resent the use of ...)");
	dma_reset();
	//shmac_printf("ok\n\r");
	
	int data_count = 16;
	uint32_t* load, load_location, load_test, store, store_location, store_test, request, request_test;
	uint32_t data[data_count];
	uint32_t data_test[data_count];
	
	
	shmac_printf("Setting Load address: 0x1000 0000 \n");
	*load = 0x10000000;
	dma_set_load_address0(load);
	
	shmac_printf("Getting Load address:\n");
	dma_get_load_address0(load_test);
	shmac_printf("This is the load address gotten: %x\n", *load_test);
	
	shmac_printf("Setting Store address: 0x4000 0000 \n");
	*store = 0x40000000;
	dma_set_load_address0(load);
	
	shmac_printf("Getting Store address:\n");
	dma_get_store_address0(store_test);
	shmac_printf("This is the store address gotten: %x\n" *store_test);
	
	shmac_printf("Setting up raw data from loading addresses, with following square numbers: 1-4-9-16-25.... (16 in total)\n");
	
	uint32_t i;
	for(i =0; i<data_count; i++){
		data[i] = (i+1)*(i+1);	
	}
	
	load_location = 0x10000000;
	uint32_t
	for(i =0; i<data_count; i++){
		load_location[i*4] = data[i];	
	}
	
	shmac_printf("Activating DMA: Count: 16 (15 + start), Byte addressing high, ON high. Hex value: 0x00F8 0001\n");
	*request = 0x00F80001;
	
	dma_set_request_details0(request);
	
	bool on = true;
	
	while(on){
		
		dma_get_request_details0(request_test); //TODO: Also test with much larger count if DMA is too fast
		
		if(request_test[3] == 0x00){
			shmac_printf("DMA transfer complete\n");
			on = false;
		} else {
			shmac_printf("DMA active. Sleep for 1000 ms\n");
			sleep(1);
		}
		
	}
	
	store_location = 0x40000000;
	for(i =0; i<data_count; i++){
		data_test[i] = store_location[i*4];	
	}
	
	shmac_printf("Now printing out data from old and new location\n");
	for(i=0, i<data_count; i++){
		shmac_printf("Old: %d, New: %d\n", data[i], data_test[i]);
	}
	
	shmac_printf("\n\rEnd programme.\n\r");
	while(1); // Burn cycles until Amber implements something like wfi
	while (1);
}


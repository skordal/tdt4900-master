// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#ifndef STRATUM_H
#define STRATUM_H

#define STRATUM_BUFFER_SIZE	4096
#define SERIAL_BUFFER_SIZE	2048
#define SHMAC_DEVNAME		"/dev/ttySHMAC0"

struct stratum_thread_params
{
	const char * hostname, * port;
	const char * username, * password;

	// Pipes to the miner control thread:
	int output_pipe, input_pipe;
};

void * stratum_thread_run(void * params);

#endif


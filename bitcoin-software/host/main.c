// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include <stdio.h>
#include <pthread.h>
#include <sys/fcntl.h>
#include <unistd.h>

#include "sha256.h"
#include "stratum.h"
#include "utilities.h"

int main(int argc, char * argv[])
{
	struct pipe_pair control_pipes;
	pthread_t stratum_thread;

	// Check command line applications:
	if(argc != 5)
	{
		printf("Usage: bitcoin-host <hostname> <port> <username> <password>\n");
		return 1;
	}

	printf("The Heterogeneous Bitcoin Miner - Host Application\n");
	printf("Live long and prosper - by (literally) making money!\n\n");

	struct stratum_thread_params sparams;
	sparams.hostname = argv[1];
	sparams.port = argv[2];
	sparams.username = argv[3];
	sparams.password = argv[4];
	sparams.output_pipe = control_pipes.a_to_b[1];
	sparams.input_pipe = control_pipes.b_to_a[0];

	// Create a pipe for communicating with the control thread:
	if(pipe(control_pipes.a_to_b) != 0 || pipe(control_pipes.b_to_a) != 0)
	{
		fprintf(stderr, "ERROR: could not create control pipes!\n");
		return 1;
	}

	// Create threads:
	if(pthread_create(&stratum_thread, NULL, stratum_thread_run, (void *) &sparams) != 0)
	{
		fprintf(stderr, "ERROR: could not create stratum thread!\n");
		return 1;
	}

	// Wait for the thread(s) to finish:
	int stratum_retval;
	pthread_join(stratum_thread, (void *) &stratum_retval);

	if(stratum_retval != 0)
		return 2;

	close(control_pipes.a_to_b[0]);
	close(control_pipes.a_to_b[1]);
	close(control_pipes.b_to_a[0]);
	close(control_pipes.b_to_a[1]);

	return 0;
}


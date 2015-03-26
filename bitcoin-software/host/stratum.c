// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <fcntl.h>
#include <termios.h>

#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>

#include <jansson.h>

#include "line_buffer.h"
#include "stratum.h"

static int server_socket = -1;
static int serial_port = -1;

static char * worker_name;

static bool stratum_subscribe(void);
static bool stratum_authenticate(const char * username, const char * password);
static bool stratum_client(void);

void * stratum_thread_run(void * arg)
{
	int status;
	struct stratum_thread_params * params = arg;

	// Open the SHMAC serial port:
	serial_port = open(SHMAC_DEVNAME, O_RDWR | O_NOCTTY | O_NONBLOCK);
	if(serial_port == -1)
	{
		fprintf(stderr, "ERROR: could not open %s!\n", SHMAC_DEVNAME);
		goto _error_exit;
	}

	// Set serial port options:
	struct termios serial_options;
	tcgetattr(serial_port, &serial_options);
	cfsetispeed(&serial_options, B9600);
	cfsetospeed(&serial_options, B9600);
	serial_options.c_cflag |= (CLOCAL | CREAD);
	serial_options.c_cflag &= ~(PARENB | CSTOPB);
	if(tcsetattr(serial_port, TCSANOW, &serial_options) != 0)
	{
		fprintf(stderr, "ERROR: could not set the serial transceiver format!\n");
		goto _error_exit;
	}

	// Resolve the server address:
	struct addrinfo address_hints;
	struct addrinfo * server_address = NULL;

	memset(&address_hints, 0, sizeof(struct addrinfo));
	address_hints.ai_family = AF_UNSPEC;
	address_hints.ai_socktype = SOCK_STREAM;

	printf("INFO: resolving server address...\n");
	status = getaddrinfo(params->hostname, params->port, &address_hints, &server_address);
	if(status != 0)
	{
		fprintf(stderr, "ERROR: could not resolve the server address for %s:%s: %s\n",
			params->hostname, params->port, gai_strerror(status));
		goto _error_exit;
	}

	char address[INET6_ADDRSTRLEN];
	memset(address, 0, INET6_ADDRSTRLEN);

	// Grab the first address from the list of possible addresses:
	if(server_address->ai_family == AF_INET) // IPv4
	{
		struct sockaddr_in * address_info = (struct sockaddr_in *) server_address->ai_addr;
		inet_ntop(server_address->ai_family, &address_info->sin_addr, address, INET_ADDRSTRLEN);
	} else { // IPv6
		struct sockaddr_in6 * address_info = (struct sockaddr_in6 *) server_address->ai_addr;
		inet_ntop(server_address->ai_family, &address_info->sin6_addr, address, INET6_ADDRSTRLEN);
	}

	// Make a socket and connect to the server:
	printf("INFO: connecting to the server...\n");
	server_socket = socket(server_address->ai_family, server_address->ai_socktype,
		server_address->ai_protocol);
	if(server_socket == -1)
	{
		int error = errno;
		fprintf(stderr, "ERROR: could not create socket: %s\n", strerror(error));
		goto _error_exit;
	}

	if(connect(server_socket, server_address->ai_addr, server_address->ai_addrlen) == -1)
	{
		int error = errno;
		fprintf(stderr, "ERROR: could not connect to the host: %s\n", strerror(error));
		goto _error_exit;
	}

	worker_name = strdup(params->username);
	printf("INFO: using %s as worker name.\n", worker_name);

	// Subscribe to receiving mining jobs:
	if(!stratum_subscribe())
		goto _error_exit;

	// Authenticate the worker:
	if(!stratum_authenticate(params->username, params->password))
		goto _error_exit;

	// Make the socket nonblocking:
	if(fcntl(server_socket, F_SETFL, O_NONBLOCK) != 0)
	{
		fprintf(stderr, "ERROR: could not make the server socket to nonblocking!\n");
		goto _error_exit;
	}

	// Send a reset command to SHMAC:
	write(serial_port, "RESET\n", 7);
	tcdrain(serial_port);

	// Start the stratum client loop:
	if(!stratum_client())
		goto _error_exit;

_success_exit:
	free(worker_name);
	shutdown(server_socket, SHUT_RDWR);
	close(server_socket);
	close(serial_port);
	return (void *) 0;

_error_exit:
	if(serial_port != -1)
		close(serial_port);
	if(server_socket != -1)
	{
		shutdown(server_socket, SHUT_RDWR);
		close(server_socket);
	}
	return (void *) 1;
}

static bool stratum_subscribe(void)
{
	bool retval = true;
	json_t * root = json_object();

	json_object_set_new(root, "id", json_integer(1));
	json_object_set_new(root, "method", json_string("mining.subscribe"));
	json_object_set_new(root, "params", json_array());

	char * raw_message = json_dumps(root, 0);
	char * message = malloc(strlen(raw_message) + 3);
	sprintf(message, "%s\n", raw_message);
	free(raw_message);

	printf("INFO: sending mining.subscribe... ");
	if(send(server_socket, message, strlen(message), 0) == -1)
	{
		int error = errno;
		fprintf(stderr, "ERROR: could not send mining.subscribe message to server: %s\n",
			strerror(error));
		retval = false;
		goto _return;
	}
	printf("ok\n");

_return:
	free(message);
	json_decref(root);
	return retval;
}

static bool stratum_authenticate(const char * username, const char * password)
{
	bool retval = true;
	json_t * root = json_object();

	json_t * auth_array = json_array();
	json_array_append_new(auth_array, json_string(username));
	json_array_append_new(auth_array, json_string(password));

	json_object_set_new(root, "id", json_integer(2));
	json_object_set_new(root, "method", json_string("mining.authorize"));
	json_object_set_new(root, "params", auth_array);

	char * raw_message = json_dumps(root, 0);
	char * message = malloc(strlen(raw_message) + 2);
	sprintf(message, "%s\n", raw_message);
	free(raw_message);

	printf("INFO: authenticating %s as worker, sending mining.authorize... ", username);
	if(send(server_socket, message, strlen(message), 0) == -1)
	{
		int error = errno;
		fprintf(stderr, "ERROR: could not send mining.authorize message to server: %s\n",
			strerror(error));
		retval = false;
		goto _return;
	}
	printf("ok\n");

_return:
	free(message);
	json_decref(root);
	return retval;
}

static bool stratum_client(void)
{
	bool retval = true;

	char * extranonce1_string = NULL;
	int extranonce2_length;
	int difficulty = 1;

	fd_set files;
	FD_ZERO(&files);
	FD_SET(server_socket, &files);
	FD_SET(serial_port, &files);

	int sret;
	char * buffer = malloc(STRATUM_BUFFER_SIZE);
	char * serial_buffer = malloc(SERIAL_BUFFER_SIZE);
	struct line_buffer * input_buffer = line_buffer_new();
	struct line_buffer * shmac_buffer = line_buffer_new();
	while((sret = select(server_socket > serial_port ? server_socket + 1 : serial_port + 1, &files, NULL, NULL, NULL)) != 0)
	{
		// Check if there is data available on the serial port:
		if(FD_ISSET(serial_port, &files))
		{
			size_t read_bytes = read(serial_port, serial_buffer, SERIAL_BUFFER_SIZE - 1);
			serial_buffer[read_bytes] = 0;
			line_buffer_append(shmac_buffer, serial_buffer);

			char * line = line_buffer_getline(shmac_buffer);
			if(line != NULL)
			{
				if(!strcmp(line, "RESET"))
				{
					printf("SHMAC: application state reset\n");
				} else if(strlen(line) > 4 && !strncmp(line, "STAT", 4))
				{
					printf("SHMAC: %s\n", line + 5);
				}

				free(line);
			}
		}

		// Check if there is data available from the Stratum server:
		if(FD_ISSET(server_socket, &files))
		{
			size_t read_bytes = read(server_socket, buffer, STRATUM_BUFFER_SIZE - 1);
			buffer[read_bytes] = 0;
			line_buffer_append(input_buffer, buffer);

			char * line = line_buffer_getline(input_buffer);
			printf("\"%s\"\n", line);
			if(line != NULL && strlen(line) > 0)
			{
				json_error_t parser_error;
				json_t * message_root = json_loads(line, 0, &parser_error);

				int message_id = json_integer_value(json_object_get(message_root, "id"));
				if(message_id == 1) // Reply to mining.subscribe
				{
					json_t * results = json_object_get(message_root, "result");
					extranonce1_string = strdup(json_string_value(json_array_get(results, 1)));
					extranonce2_length = json_integer_value(json_array_get(results, 2));

					printf("INFO: setting extranonce1 to \"%s\", extranonce2 length is %d\n",
						extranonce1_string, extranonce2_length);
					char * enonce1_message = malloc(6 + strlen(extranonce1_string));
					sprintf(enonce1_message, "EN1 %s\n", extranonce1_string);
					write(serial_port, enonce1_message, strlen(enonce1_message));
					free(enonce1_message);
				} else if(message_id == 2) // Reply to mining.authorize
				{
					json_t * results = json_object_get(message_root, "result");
					if(json_typeof(results) == JSON_FALSE)
					{
						fprintf(stderr, "Error: wrong username or password specified!\n");
						retval = false;
						break;
					} else
						printf("INFO: worker authorized successfully.\n");
				} else {
					json_t * method = json_object_get(message_root, "method");
					if(method == NULL)
					{

					} else if(!strcmp(json_string_value(method), "mining.set_difficulty")) // Difficulty updated
					{
						difficulty = json_integer_value(json_array_get(json_object_get(message_root, "params"), 0));
						printf("INFO: difficulty set to %d\n", difficulty);
					} else if(!strcmp(json_string_value(method), "mining.notify")) // New block to mine
					{
						json_t * params = json_object_get(message_root, "params");
						json_t * job_id = json_array_get(params, 0);
						json_t * prevhash = json_array_get(params, 1);
						json_t * coinb1 = json_array_get(params, 2);
						json_t * coinb2 = json_array_get(params, 3);
						json_t * merkle_branch = json_array_get(params, 4);
						json_t * version = json_array_get(params, 5);
						json_t * nbits  = json_array_get(params, 6);
						json_t * ntime = json_array_get(params, 7);
						json_t * clean = json_array_get(params, 8);

						// Only send a new job if old jobs must be deleted:
						if(json_typeof(clean) != JSON_FALSE)
						{
							write(serial_port, "RESET\n", 6);
						}
					}
				}

				json_decref(message_root);
				free(line);
			}
		}

		FD_ZERO(&files);
		FD_SET(server_socket, &files);
		FD_SET(serial_port, &files);
	}

	line_buffer_free(input_buffer);
	line_buffer_free(shmac_buffer);
	free(buffer);
	free(serial_buffer);
	free(extranonce1_string);
	return retval;
}


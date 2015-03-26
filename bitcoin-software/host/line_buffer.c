// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "line_buffer.h"

struct line_buffer
{
	char * buffer;
	int end_index;
	int buffer_length;
};

struct line_buffer * line_buffer_new(void)
{
	struct line_buffer * retval = malloc(sizeof(struct line_buffer));
	retval->buffer = malloc(LINE_BUFFER_INIT_LENGTH);
	retval->buffer[0] = 0;
	retval->end_index = 0;
	retval->buffer_length = LINE_BUFFER_INIT_LENGTH;

	return retval;
}

void line_buffer_free(struct line_buffer * buffer)
{
	free(buffer->buffer);
	free(buffer);
}

void line_buffer_append(struct line_buffer * buffer, const char * data)
{
	while(buffer->end_index + strlen(data) + 1 > buffer->buffer_length)
	{
		buffer->buffer = realloc(buffer->buffer, buffer->buffer_length + LINE_BUFFER_INCREMENT);
		buffer->buffer_length += LINE_BUFFER_INCREMENT;
	}

	strcat(buffer->buffer, data);
	buffer->end_index += strlen(data);
}

char * line_buffer_getline(struct line_buffer * buffer)
{
	char * next_line = index(buffer->buffer, '\n');

	if(next_line == NULL)
		return NULL;

	*next_line = 0;
	char * retval = strdup(buffer->buffer);

	++next_line;
	size_t new_buffer_length;
	char * new_buffer;
	if(*next_line == 0)
	{
		new_buffer_length = LINE_BUFFER_INIT_LENGTH;
		new_buffer = malloc(new_buffer_length);
		new_buffer[0] = 0;
	} else {
		new_buffer_length = strlen(next_line) < LINE_BUFFER_INIT_LENGTH ? LINE_BUFFER_INIT_LENGTH : strlen(next_line) + 1;
		new_buffer = malloc(new_buffer_length);
		strcpy(new_buffer, next_line);
	}

	free(buffer->buffer);
	buffer->buffer = new_buffer;
	buffer->buffer_length = new_buffer_length;
	buffer->end_index = *next_line == 0 ? 0 : strlen(next_line);

	return retval;
}


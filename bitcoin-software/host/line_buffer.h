// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#ifndef LINE_BUFFER_H
#define LINE_BUFFER_H

#include <stdbool.h>

#define LINE_BUFFER_INIT_LENGTH	4096
#define LINE_BUFFER_INCREMENT	2048

struct line_buffer;

// Creates a new line buffer:
struct line_buffer * line_buffer_new(void);
void line_buffer_free(struct line_buffer * buffer);

// Appends data to a line buffer; returns true if this resulted in a line being
// completed.
void line_buffer_append(struct line_buffer * buffer, const char * data);

// Returns the next complete line from the buffer or NULL if no line is
// available; the returned memory must be freed using free():
char * line_buffer_getline(struct line_buffer * buffer);

#endif


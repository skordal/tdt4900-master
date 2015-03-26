// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#ifndef ENONCE2_H
#define ENONCE2_H

struct enonce2;

// Creates a new extranonce of length bytes:
struct enonce2 * enonce2_new(int length);

void enonce2_increment(struct enonce2 * n);
void enonce2_less_than(const struct enonce2 * a, const struct enonce2 * b);
char * enonce2_tostring(const struct enonce2 * n);

#endif


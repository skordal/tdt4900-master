// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include <stdarg.h>
#include <stdbool.h>

#include "mutex.h"
#include "shmac.h"

// Tile register block:
static volatile uint32_t * tilereg = SHMAC_TILE_BASE;
// System register block:
static volatile uint32_t * sysreg = SHMAC_SYS_BASE;

// I/O mutex:
static mutex_t * io_mutex;

// Prints a character to the serial port.
static void shmac_print_char(char c);
// Prints a decimal number to the serial port:
static void shmac_print_decimal(int n);
// Prints a string to the serial port.
static void shmac_print_string(const char * string);
// Prints a hexadecimal number to the serial port.
static void shmac_print_hex(uint32_t value);

void shmac_initialize(void)
{
	if(shmac_get_tile_cpu_id() == 0)
		io_mutex = mutex_new();
}

int shmac_get_tile_cpu_id(void)
{
	return tilereg[SHMAC_TILE_CPU_ID];
}

int shmac_get_cpu_count(void)
{
	return sysreg[SHMAC_SYS_CPU_COUNT];
}

void shmac_get_tile_loc(int * x, int * y)
{
	*x = tilereg[SHMAC_TILE_X];
	*y = tilereg[SHMAC_TILE_Y];
}

void shmac_set_ready(void)
{
	sysreg[SHMAC_SYS_READY] = 1;
}

// Prints a string to the command line; basically all the I/O functions below
// here have been borrowed from <github://skordal/mordax/kernel/debug.c>.
void shmac_printf(const char * format, ...)
{
	va_list arguments;
	va_start(arguments, format);

	mutex_lock(io_mutex);

	for(int i = 0; format[i] != 0; ++i)
	{
		if(format[i] == '%')
		{
			switch(format[i + 1])
			{
				case 'c':
					shmac_print_char(va_arg(arguments, int));
					break;
				case 'd':
					shmac_print_decimal(va_arg(arguments, int));
					break;
				case 's':
					shmac_print_string(va_arg(arguments, const char *));
					break;
				case 'p':
				case 'x':
					shmac_print_string("0x");
					shmac_print_hex(va_arg(arguments, uint32_t));
					break;
				case '%':
					shmac_print_char('%');
					break;
				case '0':
				default:
					break;
			}

			++i;
		} else
			shmac_print_char(format[i]);
	}

	mutex_unlock(io_mutex);
	va_end(arguments);
}

char shmac_getc(void)
{
	while(!(sysreg[SHMAC_SYS_INT_STATUS] & 1));
	return sysreg[SHMAC_SYS_IN_DATA];
}

static void shmac_print_char(char c)
{
	while(sysreg[SHMAC_SYS_INT_STATUS] & 2);
	sysreg[SHMAC_SYS_OUT_DATA] = c;
}

static void shmac_print_decimal(int n)
{
	static char buffer[10];
	bool inside_num = false;

	// If the number is negative, print a minus sign and convert it to
	// a positive number:
	if(n & 0x80000000)
	{
		n = ~n + 1;
		shmac_print_char('-');
	}

	for(int i = 0; i < 10; ++i)
		buffer[i] = '0';
	for(int i = 9; i >= 0; --i)
	{
		buffer[i] = '0' + (n % 10);
		n /= 10;
	}

	for(int i = 0; i < 10; ++i)
	{
		// Do not print leading zeroes:
		if(!inside_num && buffer[i] == '0' && i != 9)
			continue;
		inside_num = true;
		shmac_print_char(buffer[i]);
	}
}

static void shmac_print_string(const char * string)
{
	for(int i = 0; string[i] != 0; ++i)
		shmac_print_char(string[i]);
}

static void shmac_print_hex(uint32_t value)
{
	const char * hex_digits = "0123456789abcdef";
	for(int i = 28; i >= 0; i -= 4)
		shmac_print_char(hex_digits[value >> i & 0xf]);
}


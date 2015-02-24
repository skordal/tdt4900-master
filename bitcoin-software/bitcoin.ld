/*
 * The Great Heterogenous Bitcoin Miner Project
 * Written as part of their master's thesis by:
 *	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
 *	Torbjørn Langland <torbljan@stud.ntnu.no>
 * Read the report on <https://github.com/skordal/tdt4102-master>
 */

SECTIONS
{
	. = 0x00000000; /* Base address for all CPUs tiles. */

	.text :
	{
		__code_start = .;
		*(.vectors*) /* Make sure the exception vectors are first */
		*(.text*)
	}
	__code_end = ALIGN(4);
	. = __code_end;

	.data :
	{
		__data_start = .;
		*(.rodata*)
		*(.data*)
	}
	__data_end = ALIGN(4);
	. = __data_end;

	.bss :
	{
		__bss_start = .;
		*(.bss*)
	}
	__bss_end = ALIGN(4);
	. = __bss_end;

	/* Reserve 16 Mb for stack, like in the Benchmark linker script: */
	. = . + 0x1000000;
	__stack_top = .;

	/DISCARD/ :
	{
		*(.comment)
		*(.note)
		*(.ARM.attributes)
	}
}


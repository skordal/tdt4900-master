/*
 * The Great Heterogenous Bitcoin Miner Project
 * Written as part of their master's thesis by:
 *	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
 *	Torbjørn Langland <torbljan@stud.ntnu.no>
 * Read the report on <https://github.com/skordal/tdt4102-master>
 */

SECTIONS
{
	ENTRY(_start)
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

	__dataspace_end = 0x30000000; /* Reserve the uppermost 256 Mb for stack. */

	/* Use the top of the DRAM as the top of the global stack space: */
	__stack_top = 0x40000000;

	/DISCARD/ :
	{
		*(.comment)
		*(.note)
		*(.ARM.attributes)
	}
}


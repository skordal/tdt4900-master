@ The Great Heterogenous Bitcoin Miner Project
@ Written as part of their master's thesis by:
@ 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
@	Torbjørn Langland <torbljan@stud.ntnu.no>
@ Read the report on <https://github.com/skordal/tdt4102-master>
.syntax unified
.arm

.section .vectors
exception_vectors:
	b _start
	b int_undefined_instruction
	b int_software_interrupt
	b int_prefetch_abort
	b int_data_abort
	b .
	b int_irq
	b int_fiq
.ltorg

.section .text

@ Application entry-point.
@ This function sets up neccessary context and calls the main function in the
@ C code.
.global _start
_start:
	ldr sp, =__initial_stack_top @ Setup the initial stack pointer

	@ TODO: Enable caches

clear_bss:
	ldr r4, =__bss_start
	ldr r5, =__bss_end
	mov r6, #0
1:
	cmp r4, r5
	itt ne
	strne r6, [r4], #4
	bne 1b

start_main:
	bl main

loop_forever:
	b .


@ The Great Heterogenous Bitcoin Miner Project
@ Written as part of their master's thesis by:
@ 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
@	Torbjørn Langland <torbljan@stud.ntnu.no>
@ Read the report on <https://github.com/skordal/tdt4102-master>
.syntax unified
.arm

.section .text
.global int_undefined_instruction
int_undefined_instruction:
	@ Handle undefined instruction here

	ldr r0, =undef_instr_msg
	sub r1, lr, #4
	bl shmac_printf
	b .

@	movs pc, lr @ Jump to the next instruction after the faulting one

.global int_software_interrupt
int_software_interrupt:
	@ Handle software interrupt here
	movs pc, lr @ Jump to the next instruction after the SVC/SWI

.global int_prefetch_abort
int_prefetch_abort:
	@ Handle prefetch abort (instruction load fault) here

	ldr r0, =prefetch_abt_msg
	sub r0, lr, #4
	bl shmac_printf
	b .

@	subs pc, lr, #4 @ Jump to the faulting instruction for a retry

.global int_data_abort
int_data_abort:
	@ Handle data abort (data load/write fault) here

	ldr r0, =data_abt_msg
	sub r0, lr, #8
	bl shmac_printf
	b .

@	subs pc, lr, #8 @ Jump to the faulting instruction for a retry

.global int_irq
int_irq:
	@ Handle IRQ here
	subs pc, lr, #4 @ Jump to the aborted instruction

.global int_fiq
int_fiq:
	@ Handle FIQ here
	subs pc, lr, #4 @ Jump to the aborted instruction

.section .rodata

undef_instr_msg:
	.asciz "Undefined instruction at PC = %x\n\r"

prefetch_abt_msg:
	.asciz "Prefetch abort at PC = %x\n\r"

data_abt_msg:
	.asciz "Data abort at PC = %x\n\r"


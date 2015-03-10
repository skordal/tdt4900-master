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
	@ Ensure we are in system mode with interrupts disabled:
	mov r0, #0xdf
	msr cpsr, r0

.hidden setup_stacks
setup_stacks:
	@ Set up a 8096 byte stack beginning at an offset from the global
	@ top-of-stack address dependent on the CPU ID in the system.
	ldr r0, =__stack_top	@ Load the top-of-stack address from the linker script
	ldr r1, =0xfffe0000	@ Address of the TILEREG_CPUID register
	ldr r1, [r1, #0]	@ Load the CPU ID of the current tile
	sub sp, r0, r1, lsl 13	@ Subtract CPU ID times 8096 bytes from the global stack top

	@ The bitcoin miner will only use the supervisor and IRQ modes.
	@ If an abort exception or an undefined instruction exception is taken,
	@ they will be handled in supervisor mode.
	@ The upper 4096 bytes will be used as supervisor mode stack, this is set above.

	@ The lower 4096 bytes will be used as the IRQ mode stack:
	sub r0, sp, #4096

	mrs r1, cpsr		@ Load status register
	bic r1, #0x1f		@ Clear mode bits
	orr r1, #0x12		@ Set IRQ mode
	msr cpsr, r1		@ Actually switch to IRQ mode

	mov sp, r0		@ Set the IRQ stack

	mrs r1, cpsr		@ Switch back to system mode
	orr r1, #0x1f
	msr cpsr, r1

	@ TODO: Enable caches

.hidden clear_bss
clear_bss:
	@ Ensure only CPU 0 clears the .bss section:
	ldr r0, =0xfffe0000
	ldr r0, [r0, #0]
	cmp r0, #0
	bne 2f

	ldr r4, =__bss_start
	ldr r5, =__bss_end
	mov r6, #0
1:
	cmp r4, r5
	itt ne
	strne r6, [r4], #4
	bne 1b

2:

.hidden enable_interrupts
enable_interrupts:
	bl irq_initialize

	mrs r1, cpsr
	bic r1, #0x80
	msr cpsr, r1

.hidden initialize_mm
initialize_mm:
	bl mm_initialize

.hidden start_main
start_main:
	bl main

.hidden loop_forever
loop_forever:
	b .


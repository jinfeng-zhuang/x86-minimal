#include "memmap.h"

	.global start

/*-----------------------------------------------------*/
	.code16

start:
	cli

	lgdt gdt_desc

	in $0x92, %al
	or 0x02, %al
	out %al, $0x92

	mov %cr0, %eax
	or $1, %eax
	mov %eax, %cr0

	ljmp $CS_INIT, $protected_mode_start
	
/*-----------------------------------------------------*/
	.code32

/*
 * TSS only contains ring 0 kernel stack info
 * Tasks stack info are stored in TCB array
 */
tss:
	.long 0			// prev tss
	.long STACK_INIT	// kernel stack top
	.long DS_INIT		// kernel stack segment
	.long 0,0,0,0		// for ring 1 & 2
	.long 0			// cr3
	.long 0,0		// eflags, eip
	.long 0,0,0,0		// eax - edx
	.long 0,0,0,0		// esp,ebp,esi,edi
	.long DS_INIT+3		// es
	.long CS_INIT+3		// cs
	.long DS_INIT+3		// ss
	.long DS_INIT+3		// ds
	.long DS_INIT+3		// fs
	.long DS_INIT+3		// gs
	.long 0,0		// ldt, trap & iomem_base

gdt:
	.quad 0x0000000000000000 // 0x00
	.quad 0x00CF9A000000FFFF // 0x08 ring 0 init code
	.quad 0x00CF92000000FFFF // 0x10 ring 0 init data
	.quad 0x00CFFA000000FFFF // 0x18 ring 3 init task code
	.quad 0x00CFF2000000FFFF // 0x20 ring 3 init task data
	.quad 0x0000E9007C1DFFFF // 0x28 TSS, 0x7C1D is fixed
	.quad 0x00CFFA000000FFFF // 0x30 ring 3 task A code
	.quad 0x00CFF2000000FFFF // 0x38 ring 3 task A data

gdt_desc:
	.word 8*8-1
	.long gdt

dummy_isr:
	jmp .

idt:
	.quad 0x0000870000087CCB // 0x7CCB is fixed if uppon has no change
	.quad 0x0000870000087CCB // 0x7CCB is fixed if uppon has no change

idt_desc:
	.word 8*2-1
	.long idt

protected_mode_start:
	mov $DS_INIT, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs

	lidt idt_desc

	mov $SS_TSS, %ax
	ltr %ax

	pushl $DS_TASK_INIT
	pushl $STACK_TASK_INIT
	pushfl
	pushl $CS_TASK_INIT
	pushl $user_mode_start
	iret

user_mode_start:
	mov $DS_TASK_INIT, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs

	int $1

	jmp .

/*-----------------------------------------------------*/

.fill (510 - (. - start)), 1, 0
.word 0xaa55


#include "memmap.h"
#include "clock.h"

	.global start

/*-----------------------------------------------------*/
	.code16

start:
	cli

	lgdt gdt_desc

	inb $0x92, %al
	orb 0x2, %al
	outb %al, $0x92

	movl %cr0, %eax
	orl $0x1, %eax
	movl %eax, %cr0

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

gdt_desc:
	.word 8*6-1
	.long gdt

dummy_isr:
	/* need update ds, es, fs, gs */
	jmp .

timer_isr:
	movb $0x20, %al
	outb %al, $0x20
	mov $'z', %al
	mov $0x3F8, %dx
	out %al, %dx
	iret

keyboard_isr:
	jmp .

idt:
	/* internal exceptions */
	.quad 0x0000EE0000087CBB // 0
	.quad 0x0000EE0000087CBB
	.quad 0x0000EE0000087CBB
	.quad 0x0000EE0000087CBB
	.quad 0x0000EE0000087CBB
	.quad 0x0000EE0000087CBB // 5
	.quad 0x0000EE0000087CBB
	.quad 0x0000EE0000087CBB
	.quad 0x0000EE0000087CBB
	.quad 0x0000EE0000087CBB
	.quad 0x0000EE0000087CBB // 10
	.quad 0x0000EE0000087CBB
	.quad 0x0000EE0000087CBB
	.quad 0x0000EE0000087CBD // 13: general protection fault
	.quad 0x0000EE0000087CBB
	.quad 0x0000EE0000087CBB

	/* TODO offset should be 32 */
	/* outside */
	.quad 0x0000EE0000087CBD // timer
	.quad 0x0000EE0000087CC9 // keyboard
	.quad 0x0000EE0000087CC9
	.quad 0x0000EE0000087CC9
	.quad 0x0000EE0000087CC9
	.quad 0x0000EE0000087CC9
	.quad 0x0000EE0000087CC9
	.quad 0x0000EE0000087CC9

idt_desc:
	.word 8*22-1
	.long idt

protected_mode_start:
	mov $DS_INIT, %ax
	mov %ax, %ds
	/* TODO es, fs, gs */

	/* CPU init */
	lidt idt_desc

	mov $SS_TSS, %ax
	ltr %ax

pic_init:
	movb $0x11, %al // ICW1: cascade mode, edge trigger
	out %al, $0x20
	out %al, $0xa0

	/* TODO offset should be 32 */
	movb $16, %al	// ICW2: specify the IRQ0 offset in vector table
	out %al, $0x21
	movb $24, %al
	out %al, $0xa1

	movb $0x04, %al // ICW3: Pin 3 used to connect the slave 8259A
	out %al, $0x21
	movb $0x02, %al
	out %al, $0xa1

	movb $0x01, %al	// ICW4: 80x86 mode
	out %al, $0x21
	out %al, $0xA1

	movb $0xfe, %al
	out %al, $0x21
	movb $0xff, %al
	out %al, $0xA1

timer_init:
	movb $0x36, %al
	out %al, $0x43
	movb $TIMER_DIVIDER_LOW, %al
	out %al, $0x40
	movb $TIMER_DIVIDER_HIGH, %al
	out %al, $0x40

enter_user_mode:
	pushl $DS_TASK_INIT
	pushl $STACK_TASK_INIT
	pushfl
	popl %eax
	orl $0x200, %eax
	push %eax
	pushl $CS_TASK_INIT
	pushl $user_mode_start
	iret

user_mode_start:
	mov $DS_TASK_INIT, %ax
	mov %ax, %ds
	/* TODO es, fs, gs */
	jmp .

/*-----------------------------------------------------*/

.fill (510 - (. - start)), 1, 0
.word 0xaa55


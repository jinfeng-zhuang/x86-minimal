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

gdt:
	.quad 0x0000000000000000 // 0x00
	.quad 0x00CF9A000000FFFF // 0x08 ring 0 init code
	.quad 0x00CF92000000FFFF // 0x10 ring 0 init data
	.quad 0x00CFFA000000FFFF // 0x18 ring 3 init task code
	.quad 0x00CFF2000000FFFF // 0x20 ring 3 init task data
	.quad 0x0000E9007C73FFFF // 0x28 TSS, 0x7C73 is fixed
	.quad 0x00CFFA000000FFFF // 0x30 ring 3 task A code
	.quad 0x00CFF2000000FFFF // 0x38 ring 3 task A data
	.quad 0x00CFFA000000FFFF // 0x40 ring 3 task B code
	.quad 0x00CFF2000000FFFF // 0x48 ring 3 task B data

gdt_desc:
	.word 8*5-1
	.long gdt

/* TSS is needed by CPU when change priority from low to high:
 * 	3 => 1
 * TSS only contains ring 0 kernel stack info
 * Tasks stack info are stored in TCB array
 */
tss:
	.long 0
	.long STACK_INIT	// kernel stack top
	.long DS_INIT		// kernel stack segment
	.fill 23, 4, 0

protected_mode_start:
	mov $DS_INIT, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs

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
	jmp .

/*-----------------------------------------------------*/

.fill (510 - (. - start)), 1, 0
.word 0xaa55

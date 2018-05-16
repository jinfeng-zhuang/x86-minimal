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

	ljmp $0x08, $protected_mode_start
	
/*-----------------------------------------------------*/
	.code32

protected_mode_start:
	mov %esp, %eax
	pushl $0x23
	pushl %eax
	pushfl
	pushl $0x1B
	pushl $user_mode_start
	iret

user_mode_start:
	mov $0x23, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs
	jmp .

gdt:
	.quad 0x0000000000000000 // 0x00
	.quad 0x00CF9A000000FFFF // 0x08 ring 0 init code
	.quad 0x00CF92000000FFFF // 0x10 ring 0 init data
	.quad 0x00CFFA000000FFFF // 0x18 ring 3 init code
	.quad 0x00CFF2000000FFFF // 0x20 ring 3 init data

gdt_desc:
	.word 8*5-1
	.long gdt

/*-----------------------------------------------------*/

.fill (510 - (. - start)), 1, 0
.word 0xaa55

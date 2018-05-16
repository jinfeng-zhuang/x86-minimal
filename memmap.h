#ifndef MEMMAP_H
#define MEMMAP_H

#define STACK_INIT		(0x9000)
#define STACK_TASK_INIT		(0x9000 - 128)
#define STACK_TASK_A		(0x9000 - 128 - 128)
#define STACK_TASK_B		(0x9000 - 128 - 128 - 128)

#define CS_INIT			(0x08)
#define DS_INIT			(0x10)
#define CS_TASK_INIT		(0x18+3)
#define DS_TASK_INIT		(0x20+3)
#define SS_TSS			(0x28)
#define SS_TASK_A_CODE		(0x30+3)
#define SS_TASK_A_DATA		(0x38+3)
#define SS_TASK_B_CODE		(0x40+3)
#define SS_TASK_B_DATA		(0x48+3)

#endif


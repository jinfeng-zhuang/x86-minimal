bootsector.bin: bootsector.S
	gcc -c bootsector.S
	ld -Ttext=0x7c00 -e start bootsector.o -nostdlib -o bootsector.elf
	objcopy -S bootsector.elf -O binary bootsector.bin

run:
	qemu-system-i386 bootsector.bin

clean:
	rm -f *.bin *.elf *.o

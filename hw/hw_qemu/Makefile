all:
	gcc -Wall -Werror -shared -fPIC -o hw_qemu.so interface.c qemu_common.c irq.c dma_i8257.c pic_i8259.c #rtc_mc146818.c

clean:
	rm hw_qemu.so

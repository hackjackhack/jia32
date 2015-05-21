all:
	./julia gen_instr.jl
	make -C hw/hw_qemu

clean:
	rm instr/*.jl hw/hw_qemu/hw_qemu.so

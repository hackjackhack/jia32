all:
	./julia gen_instr.jl
	make -C hw/hw_qemu

clean:
	rm instr/*.jl hw/hw_qemu/hw_qemu.so

test: FORCE
	./julia test/CPU_test.jl
	./julia test/PhysicalMemory_test.jl
	./julia test/hw/EPROM_test.jl
	./julia test/phys_ram_c_access.jl

FORCE:

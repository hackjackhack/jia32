all:
	./julia gen_instr.jl
	make -C hw/hw_qemu
	make -C deps/

clean:
	rm -rf instr/*.jl hw/hw_qemu/hw_qemu.so

depsupdate:
	make -C deps/ update

depsclean:
	make -C deps/ clean

superclean:
	rm -rf instr/*.jl hw/hw_qemu/hw_qemu.so
	make -C deps/ superclean

test: FORCE
	./julia test/CPU_test.jl
	./julia test/PhysicalMemory_test.jl
	./julia test/hw/EPROM_test.jl
	./julia test/phys_ram_c_access.jl
	./julia test/Instruction_test.jl
FORCE:

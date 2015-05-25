include("JIA32.jl")

using ArgParse

function parse_options()
	s = ArgParseSettings()

	@add_arg_table s begin
		"-m"
			help = "memory size of the virtual machine (MB)"
			arg_type = UInt64
			default = UInt64(16)
		"-b"
			help = "BIOS image file path"
			arg_type = UTF8String
			default = UTF8String("images/bios.bin")
	end

	return parse_args(s)
end

function init_c_world(mem:: PhysicalMemory)
	global g_phys_mem = mem
	const cb_phys_ram_to_buffer =
		cfunction(phys_ram_to_buffer, Void, (Culonglong, Culonglong, Ptr{UInt8},))
	const cb_buffer_to_phys_ram =
		cfunction(buffer_to_phys_ram, Void, (Culonglong, Culonglong, Ptr{UInt8},))
	
	ccall(("init_c_world", "./hw/hw_qemu/hw_qemu.so"), 
		Void,
		(Ptr{UInt8}, Ptr{Void}, Ptr{Void}),
		mem.baseptr, cb_phys_ram_to_buffer, cb_buffer_to_phys_ram)
end

function main()
	parsed_args = parse_options()

	# Create VM physical memory 
	memsize = parsed_args["m"]
	if !(8 <= parsed_args["m"] <= 65536)
		error("Memory size must be between 8 and 65536")
	end
	memsize <<= 20
	cpu = CPU(memsize)
	load_opcode(cpu)
	physmem = PhysicalMemory(memsize)
	
	init_c_world(physmem)

	# Mapping EPROM
	# Volume 3, Chapter 9.10 : The EPROM is mapped at top 4G
	eprom = EPROM(UTF8String("images/bios.bin"))
	register_phys_io_map( physmem, 
		UInt64(0x100000000) - length(eprom.imgbuf), UInt64(length(eprom.imgbuf)),
		eprom,
		eprom_r64, eprom_r32, eprom_r16, eprom_r8,
		eprom_w64, eprom_w32, eprom_w16, eprom_w8
	)

	# On IBM PC, the BIOS is also mapped at top 1M
	eprom2 = EPROM(UTF8String("images/bios.bin"))
	register_phys_io_map( physmem, 
		UInt64(0x100000) - length(eprom2.imgbuf), UInt64(length(eprom2.imgbuf)),
		eprom2,
		eprom_r64, eprom_r32, eprom_r16, eprom_r8,
		eprom_w64, eprom_w32, eprom_w16, eprom_w8
	)

	# Port I/O: I8257 DMA Controller
	i8257_1 = I8257(UInt64(0x00), 0, UInt64(0x80), -1)
	register_port_io_map(cpu, i8257_1)
	i8257_2 = I8257(UInt64(0xc0), 1, UInt64(0x88), -1)
	register_port_io_map(cpu, i8257_2)

	reset(cpu)
	loop(cpu, physmem)
end

main()

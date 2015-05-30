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
		"-t"
			help = "System time"
			arg_type = UTF8String
			default = UTF8String("20150101")
	end

	return parse_args(s)
end

function init_c_world(mem:: PhysicalMemory)
	global g_phys_mem = mem
	const jf_phys_ram_to_buffer =
		cfunction(phys_ram_to_buffer, Void, (Culonglong, Culonglong, Ptr{UInt8},))
	const jf_buffer_to_phys_ram =
		cfunction(buffer_to_phys_ram, Void, (Culonglong, Culonglong, Ptr{UInt8},))
	const jf_interrupt =
		cfunction(interrupt_for_c_hw, Void, (Ptr{Void}, Cint, Cint))
	const jf_new_timer =
		cfunction(new_timer, Clonglong, (Ptr{Void}, Ptr{Void}))
	const jf_mod_timer =
		cfunction(mod_timer, Void, (Clonglong, Culonglong))
	const jf_cancel_timer =
		cfunction(cancel_timer, Void, (Clonglong,))
	const jf_get_clock =
		cfunction(get_clock, Culonglong, ())

	ccall(("init_c_world", "./hw/hw_qemu/hw_qemu.so"), 
		Void,
		(Ptr{UInt8}, Ptr{Void}, Ptr{Void}, Ptr{Void}, Ptr{Void}, Ptr{Void}, Ptr{Void}, Ptr{Void}),
		mem.baseptr,
		jf_phys_ram_to_buffer,
		jf_buffer_to_phys_ram,
		jf_interrupt,
		jf_new_timer, jf_mod_timer, jf_cancel_timer, jf_get_clock
		)
end

function main()
	parsed_args = parse_options()

	# Create a global clock
	global g_clock = InstructionClock()

	# Create VM physical memory 
	memsize = parsed_args["m"]
	if !(8 <= parsed_args["m"] <= 65536)
		error("Memory size must be between 8 and 65536")
	end
	memsize <<= 20
	cpu = CPU(memsize)
	global g_cpu = cpu
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

	# I8259 Programmable Interrupt Controller (master and slave)
	i8259 = I8259()
	register_port_io_map(cpu, i8259)

	# I8257 DMA Controller
	i8257_1 = I8257(UInt64(0x00), 0, UInt64(0x80), -1)
	register_port_io_map(cpu, i8257_1)
	i8257_2 = I8257(UInt64(0xc0), 1, UInt64(0x88), -1)
	register_port_io_map(cpu, i8257_2)

	# MC146818 Real-Time Clock
	time_string = parsed_args["t"]
	system_time = Date(time_string, "yyyymmdd")
	mc146818 = MC146818(UInt64(0x70), i8259, 
				Dates.year(system_time),
				Dates.month(system_time),
				Dates.day(system_time))
	register_port_io_map(cpu, mc146818)
	
	connect_dev_to_irq(i8259, mc146818, 8)

	reset(cpu)
	loop(cpu, physmem)
end

main()

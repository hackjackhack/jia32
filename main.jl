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

	reset(cpu)
	loop(cpu, physmem)
#=
	println(hex(ru8(cpu, physmem, CS, UInt64(@eip(cpu)))))
	println(hex(ru8(cpu, physmem, CS, UInt64(@eip(cpu)) + 1)))
	println(hex(ru8(cpu, physmem, CS, UInt64(@eip(cpu)) + 2)))
	println(hex(ru8(cpu, physmem, CS, UInt64(@eip(cpu)) + 3)))
	println(hex(ru8(cpu, physmem, CS, UInt64(@eip(cpu)) + 4)))
	println(hex(ru8(cpu, physmem, CS, UInt64(@eip(cpu)) + 5)))
	println(hex(ru8(cpu, physmem, CS, UInt64(@eip(cpu)) + 6)))
=#
end

main()

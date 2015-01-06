require("PhysicalMemory.jl")

using ArgParse
using JIA32 

function parse_options()
	s = ArgParseSettings()

	@add_arg_table s begin
		"-m"
			help = "memory size of the virtual machine (MB)"
			arg_type = Uint64
			default = uint64(16)
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
	physmem = JIA32.PhysicalMemory(memsize * 1024 * 1024)
end

main()

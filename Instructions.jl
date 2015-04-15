include("instr/opc_list.jl")

function gen_jl_block(cpu:: CPU, mem:: PhysicalMemory)
	jl_expr = quote end
	cpu.jit_rip = @rip(cpu) 
	cpu.jit_eot = false

	b = jit_fetch8_advance(cpu, mem)
	while !cpu.jit_eot
		l = cpu.jit_insn_tbl[b](cpu, mem)
		println(l)
		push!(jl_expr.args, l)
	end

	@eval f(cpu:: CPU, mem:: PhysicalMemory) = $jl_expr
	return f
end

function find_jl_block(cpu:: CPU, mem:: PhysicalMemory)
	#= The julia code blocks are stored by their beginning physical
	   addresses. The ones with beginning addresses that belong to
 	   the same physical page are stored in a associative map. Each 
	   physical page has its own associative map =#

	# Find the associative map. Create one if not found.
	phys_ip = logical_to_physical(cpu, CS, UInt64(@ip(cpu)))
	phys_page = phys_ip >> 12

	if !haskey(cpu.jl_blocks, phys_page)
		cpu.jl_blocks[phys_page] = Dict{UInt64, Function}()
	end

	# Search in the associative map. Translate if not found.
	map = cpu.jl_blocks[phys_page]
	if haskey(map, phys_ip)
		return map[phys_ip]
	else
		f = gen_jl_block(cpu, mem)
		map[phys_ip] = f
		return f
	end
end

function emu_fetch8_advance(cpu:: CPU, mem:: PhysicalMemory)
	b:: UInt8
	if (cpu.address_size == 16)
		b = ru8(cpu, mem, CS, UInt64(@ip(cpu)))
		@ip_add!(cpu, 1)
		return b
	end
	return 0
end

function jit_fetch8_advance(cpu:: CPU, mem:: PhysicalMemory)
	b:: UInt8
	if (cpu.address_size == 16)
		b = ru8(cpu, mem, CS, cpu.jit_rip & 0xffff)
		cpu.jit_rip = (cpu.jit_rip + 1) & 0xffff
		return b
	end
	return 0
end

function emu_fetch16_advance(cpu:: CPU, mem:: PhysicalMemory)
	b:: UInt16
	if (cpu.address_size == 16)
		b = ru16(cpu, mem, CS, UInt64(@ip(cpu)))
		@ip_add!(cpu, 2)
		return b
	end
	return 0
end

function jit_fetch16_advance(cpu:: CPU, mem:: PhysicalMemory)
	b:: UInt16
	if (cpu.address_size == 16)
		b = ru16(cpu, mem, CS, cpu.jit_rip & 0xffff)
		cpu.jit_rip = (cpu.jit_rip + 2) & 0xffff
		return b
	end
	return 0
end


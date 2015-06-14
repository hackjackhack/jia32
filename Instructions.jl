include("instr/opc_list.jl")

function gen_jl_block(cpu:: CPU, mem:: PhysicalMemory)
	jl_expr = quote end
	cpu.jit_rip = @rip(cpu) 
	cpu.jit_eot = false
	cpu.jit_ip_addend = 0

	nb_instr::UInt64 = 0
	while true
		b = jit_fetch8_advance(cpu, mem)
	
		l = cpu.jit_insn_tbl[b](cpu, mem, UInt16(b))
		push!(jl_expr.args, l)
		nb_instr += 1

		# If it is not a branch instruction, generate code for IP update
		if !cpu.jit_eot
			push!(jl_expr.args, :(@rip_add!(cpu, $(cpu.jit_ip_addend))))
			cpu.jit_ip_addend = 0
		end

		if cpu.jit_eot || cpu.single_stepping
			break
		end
	end

	@eval f(cpu:: CPU, mem:: PhysicalMemory) = $jl_expr
	return JITBlock(f, nb_instr)
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
		cpu.jl_blocks[phys_page] = Dict{UInt64, JITBlock}()
	end

	# Search in the associative map. Translate if not found.
	map = cpu.jl_blocks[phys_page]
	if haskey(map, phys_ip)
		return map[phys_ip]
	else
		b = gen_jl_block(cpu, mem)
		map[phys_ip] = b
		return b
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
		cpu.jit_ip_addend += 1
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
		cpu.jit_ip_addend += 2
		return b
	end
	return 0
end


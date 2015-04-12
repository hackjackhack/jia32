include("instr/0xea.jl")

function init(cpu:: CPU)
	cpu.emu_insn_tbl[0xea] = emu_0xea
end

function fetch8_advance_ip(cpu:: CPU, mem:: PhysicalMemory)
	b:: UInt8
	if (cpu.address_size == 16)
		b = ru8(cpu, mem, CS, UInt64(@ip(cpu)))
		@ip_add!(cpu, 1)
		return b
	end
	return 0
end

function fetch16_advance_ip(cpu:: CPU, mem:: PhysicalMemory)
	b:: UInt16
	if (cpu.address_size == 16)
		b = ru16(cpu, mem, CS, UInt64(@ip(cpu)))
		@ip_add!(cpu, 2)
		return b
	end
	return 0
end



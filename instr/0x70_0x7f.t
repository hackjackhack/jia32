rel = fetch8_advance(cpu, mem)
j=	rflags_compute!(cpu)
j=	flag = cpu.rflags
if opc == 0x70
j=	jmp = ((flag & CPU_OF) != 0)
elseif opc == 0x71
j=	jmp = ((flag & CPU_OF) == 0)
elseif opc == 0x72
j=	jmp = ((flag & CPU_CF) != 0)
elseif opc == 0x73
j=	jmp = ((flag & CPU_CF) == 0)
elseif opc == 0x74
j=	jmp = ((flag & CPU_ZF) != 0)
elseif opc == 0x75
j=	jmp = ((flag & CPU_ZF) == 0)
elseif opc == 0x76
j=	jmp = ((flag & (CPU_CF | CPU_ZF)) != 0)
elseif opc == 0x77
j=	jmp = ((flag & (CPU_CF | CPU_ZF)) == 0)
elseif opc == 0x78
j=	jmp = ((flag & CPU_SF) != 0)
elseif opc == 0x79
j=	jmp = ((flag & CPU_SF) == 0)
elseif opc == 0x7a
j=	jmp = ((flag & CPU_PF) != 0)
elseif opc == 0x7b
j=	jmp = ((flag & CPU_PF) == 0)
elseif opc == 0x7c
j=	jmp = ((flag & CPU_SF) != (flag & CPU_OF))
elseif opc == 0x7d
j=	jmp = ((flag & CPU_SF) == (flag & CPU_OF))
elseif opc == 0x7e
j=	jmp = ((flag & CPU_ZF) != 0 || (flag & CPU_SF) != (flag & CPU_OF))
elseif opc == 0x7f
j=	jmp = ((flag & CPU_ZF) == 0 && (flag & CPU_SF) == (flag & CPU_OF))
else
	error("Should never happen")
end

j=	if jmp
j=		temp_ip = @rip(cpu) + $$rel + $$(cpu.this_instr_len)
if cpu.operand_size == 16
j=		temp_ip &= 0xffff 
end
j=		@rip!(cpu, temp_ip)
j=	else
j=		@rip_add!(cpu, $$(cpu.this_instr_len))
j=	end
jo=	cpu.jit_eot = true

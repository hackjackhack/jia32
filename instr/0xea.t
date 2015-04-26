if cpu.operand_size == 16
	offset = fetch16_advance(cpu, mem)
	seg = fetch16_advance(cpu, mem)
	#= According to the spec, the offset should be checked
	   against segment limit. But there is no protection
	   in real mode. Not sure if the check should be performed =#
j=	@sreg!(cpu, CS, $$seg)
j=	@sreg_base!(cpu, CS, UInt64($$seg) << 4)
j=	@eip!(cpu, ($$offset & 0xffff))
jo=	cpu.jit_eot = true
end

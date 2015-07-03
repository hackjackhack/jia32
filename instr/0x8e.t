call= modrm modrm,mod,rm,reg,disp,is_reg,ev_reg,t_addr,seg
if reg == CS
	error("TODO: Throw invalid opcode exception")
end

if (cpu.cr0 & CR0_PE) == 0
	# Real mode
	if is_reg
j=		t = UInt64(@reg_r(cpu, UInt16, $$ev_reg))
j=		@sreg!(cpu, $$reg, t % UInt16)
j=		@sreg_base!(cpu, $$reg, t << 4)
	else
j=		t = UInt64(ru16(cpu, mem, $$seg, UInt64(t_addr)))
j=		@sreg!(cpu, $$reg, t % UInt16)
j=		@sreg_base!(cpu, $$reg, t << 4)
	end
end

call= modrm modrm,mod,rm,reg,disp,is_reg,ev_reg,t_addr,seg
if cpu.operand_size == 16
	if is_reg
j=		a = @reg_r(cpu, UInt16, $$ev_reg)
j=		b = @reg_r(cpu, UInt16, $$reg)
j=		@reg_w!(cpu, UInt16, $$ev_reg, a $ b)
j=		cpu.lazyf_op = OP_XOR
j=		cpu.lazyf_width = 16
j=		cpu.lazyf_op1 = a
j=		cpu.lazyf_op2 = b
	else
j=		a = @reg_r(cpu, UInt16, $$reg)
j=		b = ru16(cpu, mem, $$seg, t_addr)
j=		wu16(cpu, mem, $$seg, t_addr, a $ b)
j=		cpu.lazyf_op = OP_XOR
j=		cpu.lazyf_width = 16
j=		cpu.lazyf_op1 = a
j=		cpu.lazyf_op2 = b
	end
end

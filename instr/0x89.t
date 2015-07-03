call= modrm modrm,mod,rm,reg,disp,is_reg,ev_reg,t_addr,seg
if cpu.operand_size == 16
	if is_reg
j=		@reg_w!(cpu, UInt16, $$ev_reg, @reg_r(cpu, UInt16, $$reg))
	else
j=		wu16(cpu, mem, $$seg, UInt64(t_addr), @reg_r(cpu, UInt16, $$reg))
	end
end

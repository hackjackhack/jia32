call= modrm modrm,mod,rm,reg,disp,is_reg,ev_reg,t_addr,seg
if is_reg
j=	@reg_w!(cpu, UInt8, $$ev_reg, @reg_r(cpu, UInt8, $$reg))
else
j=	wu8(cpu, mem, $$seg, t_addr, @reg_r(cpu, UInt8, $$reg))
end

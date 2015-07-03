op_funcs ::Array{Function} = [ +, |, +, -, &, -, $, - ]
op_types ::Array{Int} = [ OP_ADD, OP_OR, OP_ADC, OP_SBB, OP_AND, OP_SUB, OP_XOR, OP_CMP ]

call= modrm modrm,mod,rm,reg,disp,is_reg,ev_reg,t_addr,seg
op_dst_type:: Type
op_src_type:: Type

if cpu.operand_size == 16
	if opc == 0x80
		# Eb, Ib
		op_dst_type = UInt8
		op_src_type = UInt8
		f_fch = fetch8_advance
	elseif opc == 0x81
		# Ev, Iz
		op_dst_type = UInt16
		op_src_type = UInt16
		f_fch = fetch16_advance
	elseif opc == 0x82
		# Eb, Ib (i64)
		op_dst_type = UInt8
		op_src_type = UInt8
		f_fch = fetch8_advance
	elseif opc == 0x83
		# Ev, Ib (Sign extended)
		op_dst_type = UInt16
		op_src_type = UInt8
		f_fch = fetch8_advance
	else
		error("Should never happen")
	end

	imm = f_fch(cpu, mem)
j=	b = UInt64($$imm)

	# Group 1 extension use reg as opcode extension
	if op_types[@ZB(reg)] == OP_ADC || op_types[@ZB(reg)] == OP_SBB
j=		rflags_compute!(cpu)
j=		b += (cpu.rflags & CPU_CF)
	end
	
	if is_reg
j=		a = UInt64(@reg_r(cpu, $$op_dst_type, $$ev_reg))
	else
		if op_dst_type == UInt16
			ru_f = ru16
			wu_f = wu16
		elseif op_dst_type == UInt8
			ru_f = ru16
			wu_f = wu16
		else
			error("Should never happen")
		end

j=		a = UInt64($$(ru_f)(cpu, mem, $$seg, t_addr))
	end

j=	r = $$(op_funcs[@ZB(reg)])(a, b)
	if is_reg
j=		@reg_w!(cpu, $$op_dst_type, $$ev_reg, r % $$op_dst_type)
	else
j=		$$(wu_f)(cpu, mem, $$seg, t_addr, r % $$op_dst_type)
	end

	if op_types[@ZB(reg)] == OP_ADC
j=		cpu.lazyf_op = (cpu.rflags & CPU_CF == 0) ? OP_ADD : OP_ADC
	elseif op_types[@ZB(reg)] == OP_SBB
j=		cpu.lazyf_op = (cpu.rflags & CPU_CF == 0) ? OP_SUB : OP_SBB
	else
j=		cpu.lazyf_op = $$(op_types[@ZB(reg)])
	end
j=	cpu.lazyf_width = $$(op_dst_type == UInt8 ? 8 : 16)
j=	cpu.lazyf_op1 = a
j=	cpu.lazyf_op2 = b
end

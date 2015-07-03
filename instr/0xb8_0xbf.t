if cpu.operand_size == 16
	imm16 = fetch16_advance(cpu, mem)
	if opc == 0xb8
j=		@reg_w_named!(cpu, AX, $$imm16)
	elseif opc == 0xb9
j=		@reg_w_named!(cpu, CX, $$imm16)
	elseif opc == 0xba
j=		@reg_w_named!(cpu, DX, $$imm16)
	elseif opc == 0xbb
j=		@reg_w_named!(cpu, BX, $$imm16)
	elseif opc == 0xbc
j=		@reg_w_named!(cpu, SP, $$imm16)
	elseif opc == 0xbd
j=		@reg_w_named!(cpu, BP, $$imm16)
	elseif opc == 0xbe
j=		@reg_w_named!(cpu, SI, $$imm16)
	elseif opc == 0xbf
j=		@reg_w_named!(cpu, DI, $$imm16)
	else
		error("Should never happen")
	end
end

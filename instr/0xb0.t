imm8 = fetch8_advance(cpu, mem)
j=@reg_w_named!(cpu, AL, $$imm8)

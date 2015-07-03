sub= modrm,mod,rm,reg,disp,is_reg,ev_reg,t_addr,seg

modrm = fetch8_advance(cpu, mem)
mod = (modrm >> 6) & 0b11
rm = modrm & 0b111
reg = (modrm & 0b00111000) >> 3
disp = 0

if cpu.address_size == 16
	# 16-bit addressing form, Vol. 2A 2-5, Table 2-1

	if mod != 0b11
		is_reg = false
		# Fetch displacement according to MOD 
		if mod == 0b00
			disp = 0
			if rm == 0b110
				disp = fetch16_advance(cpu, mem)
				
				# Avoid SS override. See note 1 below Table 2-1
				rm = -1
			end	
		elseif mod == 0b01
			disp = fetch8_advance(cpu, mem)
		elseif mod == 0b10
			disp = fetch16_advance(cpu, mem)
		else # mod == 0b11
			disp = 0
		end

		# Calculate address according to R/M
		if rm == 0
j=			t_addr = @reg_r_named(cpu, BX) + @reg_r_named(cpu, SI)
		elseif rm == 1
j=			t_addr = @reg_r_named(cpu, BX) + @reg_r_named(cpu, DI)
		elseif rm == 2
j=			t_addr = @reg_r_named(cpu, BP) + @reg_r_named(cpu, SI)
		elseif rm == 3
j=			t_addr = @reg_r_named(cpu, BP) + @reg_r_named(cpu, DI)
		elseif rm == 4
j=			t_addr = @reg_r_named(cpu, SI)
		elseif rm == 5
j=			t_addr = @reg_r_named(cpu, DI)
		elseif rm == 6
j=			t_addr = @reg_r_named(cpu, BP)
		elseif rm == 7
j=			t_addr = @reg_r_named(cpu, BX)
		else
j=			t_addr = 0
		end

		# Add displacement
		if disp != 0
j=			t_addr += $$disp
		end

		# Truncate to 16 bit
j=		t_addr &= 0xffff

		# Decide segment. See note 1 below Vol. 2A 2-5, Table 2-1
		if cpu.segment == -1
			if rm == 0b010 || rm == 0b011 || rm == 0b110
				seg = SS
			else
				seg = DS
			end
		else
			seg = cpu.segment
		end
	else
		is_reg = true
		ev_reg = rm
	end
end

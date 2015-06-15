# Operation function & type
op_funcs ::Array{Function, 1} = [ +, +, &, $ ]
op_types ::Array{Int, 1} = [ OP_ADD, OP_ADC, OP_AND, OP_XOR ]

# Get the lower/higher part of opcode
opc_h ::UInt8 = (opc & 0xf0) >> 4
opc_l ::UInt8 =  opc & 0x0f

op_func ::Function = op_funcs[@ZB(opc_h)]
op_type ::Int = op_types[@ZB(opc_h)]

# Operand type
ot ::Type
ot_width ::UInt8

if cpu.operand_size == 16

    if opc_l == 0x04 || opc_l == 0x05
        if opc_l & 0x01 == 0 
            ot       = UInt8
            ot_width = 8

            f_fetch = fetch8_advance
        else
            ot       = UInt16
            ot_width = 16

            f_fetch = fetch16_advance
        end

        imm = f_fetch(cpu, mem)
j=      b = $$imm
        if op_type == OP_ADC 
j=          rflags_compute!(cpu)
j=          b += (cpu.rflags & CPU_CF)
        end

j=      a = @reg_r(cpu, $$ot, 0)
j=      r = $$op_func(a, b)
j=      @reg_w!(cpu, $$ot, 0, r)
    else
call= modrm modrm,mod,rm,reg,disp,is_reg,ev_reg,t_addr,seg
        if is_reg
            if opc_l & 0x02 == 0
                r_dst = ev_reg
                r_src = reg
            else
                r_dst = reg
                r_src = ev_reg
            end

            if opc_l & 0x01 == 0
                ot       = UInt8
                ot_width = 8
            else
                ot       = UInt16
                ot_width = 16
            end

j=          a = @reg_r(cpu, $$ot, $$r_dst)
j=          b = @reg_r(cpu, $$ot, $$r_src)
            if op_type == OP_ADC 
j=              rflags_compute!(cpu)        
j=              b += (cpu.rflags & CPU_CF)
            end
j=          r = $$op_func(a, b)
j=          @reg_w!(cpu, $$ot, $$r_dst, r)

        else       
            if opc_l & 0x01 == 0
                ot       = UInt8
                ot_width = 8

                f_ru = ru8
                f_wu = wu8
            else
                ot       = UInt16
                ot_width = 16

                f_ru = ru16
                f_wu = wu16
            end

            # in this opcode group, each operation is commutative
j=          a = $$f_ru(cpu, mem, $$seg, t_addr)
j=          b = @reg_r(cpu, $$ot, $$reg)
j=          r = $$op_func(a, b)
            if op_type == OP_ADC 
j=              rflags_compute!(cpu)        
j=              r += (cpu.rflags & CPU_CF)
            end

            if opc_l & 0x02 == 0
j=              $$f_wu(cpu, mem, $$seg, t_addr, r)
            else
j=              @reg_w!(cpu, UInt8, $$reg, r)
            end
        end
    end
    
j=  cpu.lazyf_op = $$op_type
j=  cpu.lazyf_width = $$ot_width
j=  cpu.lazyf_op1 = a
j=  cpu.lazyf_op1 = b

end

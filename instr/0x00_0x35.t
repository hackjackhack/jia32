ops      = [ +, +, &, $ ]
op_types = [ OP_ADD, OP_ADC, OP_AND, OP_XOR ]

opc_h = (opc & 0xF0) >> 4
opc_l =  opc & 0x0F

# since julia is 1-base index, we add the index by 1
op_idx  = opc_h + 1

op       = ops[op_idx]
op_type  = op_types[op_idx]
op_witdh = 0

if cpu.operand_size == 16
    if op_l == 4
        imm = fetch8_advance(cpu, mem);
j=      b = $$imm
        if op_type == OP_ADC 
j=          b += (cpu.rflags & 0x01)
        end
j=      a = @reg_r(cpu, UInt8, 0);
j=      r = eval(Expr(:call, op, a, b))
j=      @reg_w!(cpu, UInt8, 0, r)
j=      op_witdh = 8
    elseif op_l == 5
        imm = fetch16_advance(cpu, mem);
j=      b = $$imm
        if op_type == OP_ADC 
j=          b += (cpu.rflags & 0x01)
        end
j=      a = @reg_r(cpu, UInt16, 0);
j=      r = eval(Expr(:call, op, a, b))
j=      @reg_w!(cpu, UInt16, 0, r)
j=      op_width = 16
    else
call= modrm modrm,mod,rm,reg,disp,is_reg,ev_reg,t_addr,seg
        if is_reg
            if opc_l == 0
                dst = ev_reg
                src = reg
                op_width   = 8
                op_width_t = UInt8
            elseif opc_l == 1
                dst = ev_reg
                src = reg
                op_width   = 16
                op_width_t = UInt16
            elseif opc_l == 2   
                dst = reg
                src = ev_reg
                op_width   = 8
                op_width_t = UInt8
            else # opc_l == 3
                dst = reg
                src = ev_reg
                op_width   = 16
                op_width_t = UInt16
            end

j=          a = @reg_r(cpu, $$op_width_t, $$dst)
j=          b = @reg_r(cpu, $$op_width_t, $$src)
            if op_type == OP_ADC 
j=              b += (cpu.rflags & 0x01)
            end
j=          r = eval(Expr(:call, op, a, b))
j=          @reg_w!(cpu, $$op_width_t, $$dst, r)
        else
            if opc_l == 0
j=              a = ru8(cpu, mem, $$seg, t_addr)
j=              b = @reg_r(cpu, UInt8, $$reg)
                if op_type == OP_ADC 
j=                  b += (cpu.rflags & 0x01)
                end
j=              r = eval(Expr(:call, op, a, b))
j=              wu8(cpu, mem, $$seg, t_addr, r)
                op_width = 8
            elseif opc_l == 1
j=              a = ru16(cpu, mem, $$seg, t_addr)
j=              b = @reg_r(cpu, UInt16, $$reg)
                if op_type == OP_ADC 
j=                  b += (cpu.rflags & 0x01)
                end
j=              r = eval(Expr(:call, op, a, b))
j=              wu16(cpu, mem, $$seg, t_addr, r)
                op_width = 16               
            elseif opc_l == 2   
j=              a = @reg_r(cpu, UInt8, $$reg)
j=              b = ru8(cpu, mem, $$seg, t_addr)
                if op_type == OP_ADC 
j=                  b += (cpu.rflags & 0x01)
                end
j=              r = eval(Expr(:call, op, a, b))
j=              @reg_w!(cpu, UInt8, $$reg, r)
                op_width = 8                              
            else # opc_l == 3
j=              a = @reg_r(cpu, UInt16, $$reg)
j=              b = ru16(cpu, mem, $$seg, t_addr)
                if op_type == OP_ADC 
j=                  b += (cpu.rflags & 0x01)
                end
j=              r = eval(Expr(:call, op, a, b))
j=              @reg_w!(cpu, UInt16, $$reg, r)
                op_width = 16               
            end
           
        end
    end
    
j=  cpu.lazyf_op = op_type
j=  cpu.lazyf_width = op_width
j=  cpu.lazyf_op1 = a
j=  cpu.lazyf_op1 = b

end

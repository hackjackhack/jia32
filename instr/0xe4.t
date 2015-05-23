port = fetch8_advance(cpu, mem)
j=@reg_w_named!(cpu, AL, port_io_r8(cpu, UInt64($$port)))

port = fetch8_advance(cpu, mem)
j=port_io_w8(cpu, UInt64($$port), @reg_r_named(cpu, AL))

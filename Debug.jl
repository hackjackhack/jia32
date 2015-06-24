function assemble_at_ip(cpu:: CPU, mem:: PhysicalMemory, instr_mnemonic:: String, mode:: Type)
	# as can only output to file. Any better options?
	tmpfn = tempname()
	run(pipe(`echo $instr_mnemonic`, `as -msyntax=intel -mmnemonic=intel -mnaked-reg -o $tmpfn`))
	run(`objcopy -j .text -O binary $tmpfn`)
	bin = readbytes(open(tmpfn))
	run(`rm $tmpfn`)

	# as does not support real-mode assembling. We have to manually remove 66 prefix.
	if mode == UInt16 && bin[1] == 0x66
		bin = bin[2:end]
	end

	i = 0
	for b in bin
		# println(hex(b))
		wu8_debug(cpu, mem, CS, @rip(cpu) + i, b)
		i += 1
	end
end

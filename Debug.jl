function assemble_at_ip(cpu:: CPU, mem:: PhysicalMemory, instr_mnemonic:: String)
	tmpfn = tempname()
	run(pipe(`echo $instr_mnemonic`, `as -msyntax=intel -mmnemonic=intel -mnaked-reg -o $tmpfn`))
	run(`objcopy -j .text -O binary $tmpfn`)
	bin = readall(tmpfn)
	run(`rm $tmpfn`)

	#for b in bin
	#	wu8(cpu, mem, CS, @rip(cpu), b)
	#end
	#println(bin) 
end

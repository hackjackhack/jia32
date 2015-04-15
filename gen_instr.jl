#= Template rules:
	1. Text "fetch" is preserved. Don't use it except in fetch??_advance
	2. Lines starting with j= will be written into Expr.
	3. $ in lines starting with j= will be removed in emulaion code.
	4. Lines starting with jo= will appear only in JIT code.
	5. Normal lines appear exactly the same on both sides.
	6. emu_ and jit_ will be added before any fetch 
=# 

cd("instr/")
opc_list = []

for fn in filter( x -> endswith(x, ".t"), readdir())
	instr_n = split(fn, ".")[1]
	push!(opc_list, instr_n)

	f = open(fn)
	fjl = open(instr_n * ".jl", "w")

	emu_str = "function emu_$instr_n(cpu:: CPU, mem:: PhysicalMemory)\n"
	jit_str = "function jit_$instr_n(cpu:: CPU, mem:: PhysicalMemory)
	jl_expr = quote end\n"

	for l in readlines(f)
		if startswith(l, "j=")
			emu_str *= "\t" * replace(l[3:end], "\$", "")
			n_tab = count(x -> x == '\t', l)
			jit_str *= "\t" ^ (n_tab + 1) * "push!(jl_expr.args, :($(l[3:end - 1])))\n" 
		elseif startswith(l, "jo=")
			jit_str *= "\t" * l[4:end]
		else
			emu_str *= "\t" * l
			jit_str *= "\t" * l
		end
	end

	emu_str *= "end\n"
	jit_str *= "\treturn jl_expr\nend\n"

	write(fjl, replace(emu_str, "fetch", "emu_fetch"))
	write(fjl, "\n")
	write(fjl, replace(jit_str, "fetch", "jit_fetch"))
	close(fjl)
	close(f)
end

f_inc = open("opc_list.jl", "w")
for opc in opc_list
	write(f_inc, "include(\"$opc.jl\")\n")
end
write(f_inc, "function load_opcode(cpu:: CPU)\n")
for opc in opc_list
	write(f_inc, "\tcpu.emu_insn_tbl[$opc] = emu_$opc\n")
	write(f_inc, "\tcpu.jit_insn_tbl[$opc] = jit_$opc\n")
end
write(f_inc, "end\n")
close(f_inc)

#= Template rules:
	1. Text "fetch" is preserved. Don't use it except in fetch??_advance
	2. Lines starting with j= will be written into Expr.
	3. $$ in lines starting with j= will be removed in emulaion code and
	   replaced with $ in JIT code.
	4. Lines starting with jo= will appear only in JIT code.
	5. Normal lines appear exactly the same on both sides.
	6. emu_ and jit_ will be added before any fetch
	7. inc= XXXX will include the content in XXXX.t
=# 

function translate_template(lines)
	emu_str = ""
	jit_str = ""

	for l in lines
		if startswith(l, "j=")
			emu_str *= "    " * replace(l[3:end], "\$\$", "")
			n_tab = count(x -> x == '\t', l)
			l = replace(l, "\$\$", "\$")
			jit_str *= "    " ^ (n_tab + 1) * "push!(jl_expr.args, :($(l[3:end - 1])))\n" 
		elseif startswith(l, "jo=")
			jit_str *= "    " * l[4:end]
		elseif startswith(l, "sub=")
			# sub= is used for the check in call=. It has nothing to do with the translation.
		elseif startswith(l, "call=")
			n_tab = count(x -> x == '\t', l)
			params = split(l, " ")
			f_sub = open("$(params[2]).t")
			sub_lines = readlines(f_sub)
			if !startswith(sub_lines[1], "sub=")
				error("Template $(params[2]).t must start with sub=")
			end
			if chomp(params[3]) != chomp(sub_lines[1][6:end])
				println(chomp(params[3]))
				error("You must explicitly put the output variable list '$(chomp(sub_lines[1][6:end]))' after call= $(params[2])")
			end
			
			generated_code = translate_template(sub_lines)
			emu_str *= generated_code[1]
			jit_str *= generated_code[2]
		else
			emu_str *= "    " * l
			jit_str *= "    " * l
		end
	end

	return [emu_str, jit_str]
end

function generate_emu_jit_code(opcode, lines)
	emu_str = "function emu_$opcode(cpu:: CPU, mem:: PhysicalMemory, opc:: UInt16)\n"
	jit_str = "function jit_$opcode(cpu:: CPU, mem:: PhysicalMemory, opc:: UInt16)\n"
	jit_str *= "    jl_expr = quote end\n"

	translated_code = translate_template(lines)
	emu_str *= translated_code[1]
	jit_str *= translated_code[2]

	emu_str *= "end\n"
	jit_str *= "    return jl_expr\nend\n"

	return [emu_str, jit_str]
end


cd("instr/")
opc_list = []

for fn in filter( x -> endswith(x, ".t"), readdir())
	instr_n = split(fn, ".")[1]
	if !startswith(instr_n, "0x")
		continue
	end

	print("Synthesizing $instr_n.jl ...")
 	push!(opc_list, instr_n)

	f = open(fn)
	fjl = open(instr_n * ".jl", "w")

	generated_code = generate_emu_jit_code(instr_n, readlines(f))

	write(fjl, replace(generated_code[1], "fetch", "emu_fetch"))
	write(fjl, "\n")
	write(fjl, replace(generated_code[2], "fetch", "jit_fetch"))
	close(fjl)
	close(f)
	println("done")
end



print("Synthesizing opc_list.jl ...")
f_inc = open("opc_list.jl", "w")
for opc in opc_list
	write(f_inc, "include(\"$opc.jl\")\n")
end
write(f_inc, "function load_opcode(cpu:: CPU)\n")
for opc in opc_list
    if contains(opc, "_")
        range  = split(replace(opc, "0x", ""), "_")

        opc_st  = parse(UInt8, range[1], 16)
        opc_stl = opc_st & 0x0F
        opc_sth = (opc_st & 0xF0) >> 4

        opc_ed  = parse(UInt8, range[2], 16)
        opc_edl = opc_ed & 0x0F
        opc_edh = (opc_ed & 0xF0) >> 4

        # NOTE: the opcode is strictly increased
        for i = opc_sth:opc_edh, j = opc_stl:opc_edl
            # reunion as a opcode
            k = "0x" * hex((i<<4) | j)
            write(f_inc, "\tcpu.emu_insn_tbl[$k] = emu_$opc\n")
        	write(f_inc, "\tcpu.jit_insn_tbl[$k] = jit_$opc\n")
        end
    else
	    write(f_inc, "\tcpu.emu_insn_tbl[$opc] = emu_$opc\n")
    	write(f_inc, "\tcpu.jit_insn_tbl[$opc] = jit_$opc\n")
    end
end
write(f_inc, "end\n")
close(f_inc)
println("done")

#= Template rules:
	1. Text "fetch" is preserved. Don't use it except in fetch??_advance
	2. Lines starting with j= are
		 copied into emu_0x??
		 transformed to Expr and used by jit_0x?? to generate JIT code
	3. $$ in lines starting with j= will be removed in emulaion code and
	   replaced with $ in JIT code.
	4. Lines starting with jo= will appear only in jit_0x?? functions.
	         (They are not injected to JIT block)
	5. Normal lines appear exactly the same on both sides.
	6. emu_ and jit_ will be added before any fetch
	7. inc= XXXX will include the content in XXXX.t
	8. To define a template for an opcode group, name the file with 0xYY_0xZZ.t
	   The corresponding 0xYY_0xZZ.jl will be generated to emulate these opcode

	   NOTE that the covered opcode are 0x[Y-Z] ~ 0x[Y-Z] instead of 0xYY ~ 0xZZ

	   For example: 
	   0x00_0x35.t will generate the instruction emulation code for
	   0x00, 0x01, 0x02, 0x03, 0x04, 0x05,
	   0x10, 0x11, 0x12, 0x13, 0x15, 0x15,
	   				   ...

	   0x30, 0x31, 0x32, 0x33, 0x35, 0x35
	   opcodes.
=# 

function translate_template(lines)
	emu_str = ""
	jit_str = ""

	for l in lines
		if startswith(l, "j=")
			emu_str *= "	" * replace(l[3:end], "\$\$", "")
			n_tab = count(x -> x == '\t', l)
			l = replace(l, "\$\$", "\$")
			l = strip(l[3:end - 1])

			if startswith(l, "if") && !endswith(l, "end")
				l *= " end"
				jit_str *= "	" ^ (n_tab + 1) * "push!(jl_exprs[end].args, :($(l)))\n" 
				jit_str *= "    " ^ (n_tab + 1) * "push!(jl_exprs, quote end)\n"
				jit_str *= "    " ^ (n_tab + 1) * "push!(insert_poses, 2)\n"
			elseif startswith(l, "end")
				jit_str *= "    " ^ (n_tab + 1) * "body = pop!(jl_exprs)\n"
				jit_str *= "    " ^ (n_tab + 1) * "insert_pos = pop!(insert_poses)\n"
				jit_str *= "	" ^ (n_tab + 1) * "insert!(jl_exprs[end].args[end].args, insert_pos, body)\n" 
			else
				jit_str *= "	" ^ (n_tab + 1) * "push!(jl_exprs[end].args, :($(l)))\n" 
			end
		elseif startswith(l, "jo=")
			jit_str *= "	" * l[4:end]
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
			emu_str *= "	" * l
			jit_str *= "	" * l
		end
	end

	return [emu_str, jit_str]
end

function generate_emu_jit_code(opcode, lines)
	emu_str = "function emu_$opcode(cpu:: CPU, mem:: PhysicalMemory, opc:: UInt16)\n"
	jit_str = "function jit_$opcode(cpu:: CPU, mem:: PhysicalMemory, opc:: UInt16, expr:: Expr)\n"
	jit_str *= "	jl_exprs = []\n    push!(jl_exprs, expr)\n"
	jit_str *= "    insert_poses = []\n    push!(insert_poses, 1)\n"

	translated_code = translate_template(lines)
	emu_str *= translated_code[1]
	jit_str *= translated_code[2]

	emu_str *= "end\n"
	#jit_str *= "	return jl_exprs[end]\nend\n"
	jit_str *= "end\n"

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

		opc_st	= parse(UInt8, range[1], 16)
		opc_stl = opc_st & 0x0F
		opc_sth = (opc_st & 0xF0) >> 4

		opc_ed	= parse(UInt8, range[2], 16)
		opc_edl = opc_ed & 0x0F
		opc_edh = (opc_ed & 0xF0) >> 4

		# NOTE: the opcode is strictly increased as decribed at the beginning
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

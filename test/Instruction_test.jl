include("../JIA32.jl")

function test_instr(cpu:: CPU, mem:: PhysicalMemory, instr:: String, mode:: Type, pre:: Expr, post:: Expr)
	test_expr = quote end
	push!(test_expr.args, pre)
	push!(test_expr.args, :(assemble_at_ip(cpu, mem, $instr, $mode)))
	push!(test_expr.args, :(exec(cpu, mem)))
	push!(test_expr.args, post)
	@eval t(cpu:: CPU, mem::PhysicalMemory) = $test_expr
	return t(cpu, mem)
end

macro T16(instr, pre, post)
	quote
		if !test_instr(cpu, mem, $instr, UInt16, $pre, $post) 
			error("Instruction test " * $instr * " failed.")
		end
	end
end

macro AL() :(@reg_r_named(cpu, AL)) end
macro AX() :(@reg_r_named(cpu, AX)) end
macro EAX() :(@reg_r_named(cpu, EAX)) end
macro RAX() :(@reg_r_named(cpu, RAX)) end
macro CL() :(@reg_r_named(cpu, CL)) end
macro CX() :(@reg_r_named(cpu, CX)) end
macro ECX() :(@reg_r_named(cpu, ECX)) end
macro RCX() :(@reg_r_named(cpu, RCX)) end
macro DL() :(@reg_r_named(cpu, DL)) end
macro DX() :(@reg_r_named(cpu, DX)) end
macro EDX() :(@reg_r_named(cpu, EDX)) end
macro RDX() :(@reg_r_named(cpu, RBX)) end
macro BL() :(@reg_r_named(cpu, BL)) end
macro BX() :(@reg_r_named(cpu, BX)) end
macro EBX() :(@reg_r_named(cpu, EBX)) end
macro RBX() :(@reg_r_named(cpu, RBX)) end
macro SP() :(@reg_r_named(cpu, SP)) end
macro ESP() :(@reg_r_named(cpu, ESP)) end
macro RSP() :(@reg_r_named(cpu, RSP)) end
macro BP() :(@reg_r_named(cpu, BP)) end
macro EBP() :(@reg_r_named(cpu, EBP)) end
macro RBP() :(@reg_r_named(cpu, RBP)) end
macro SI() :(@reg_r_named(cpu, SI)) end
macro ESI() :(@reg_r_named(cpu, ESI)) end
macro RSI() :(@reg_r_named(cpu, RSI)) end
macro DI() :(@reg_r_named(cpu, DI)) end
macro EDI() :(@reg_r_named(cpu, EDI)) end
macro RDI() :(@reg_r_named(cpu, RDI)) end
macro IP() :(@reg_r_named(cpu, IP)) end
macro EIP() :(@reg_r_named(cpu, EIP)) end
macro RIP() :(@reg_r_named(cpu, RIP)) end

function main()
	# Create a global clock
	global g_clock = InstructionClock()
	# Create VM physical memory 
	memsize = UInt64(16 << 20)
	cpu = CPU(memsize)
	global g_cpu = cpu
	load_opcode(cpu)
	mem = PhysicalMemory(memsize)
	
	reset(cpu)

	# Since we don't have EPROM mapped at top 4G, we have to change
        # CS segment to lower space so that assemble_at_ip() stays
	# within physical memory boundary.
	@sreg_base!(cpu, CS, 0xF0000)

	cpu.single_stepping = true

#= Example of test case writing
	@T16("xor ax, bx",
		quote
			a = @AX() $ @BX()
		end,
		quote
			println(a == @AX())
		end
	)

	@T16("xor ax, bx", :(a = @AX() $ @BX()), :(println(a == @AX())))
=#

	# Test case starts here
	@T16("xor ax, bx", :(a = @AX() $ @BX()), :(a == @AX()))
	@T16("add ax, cx", :(a = (UInt32(@AX()) + UInt32(@CX())) % UInt16), :(a == @AX()))

	@T16("xor ax, ax", quote end, quote true end) 
	@T16("xor bx, bx", quote end, quote true end) 
	@T16("cmp ax, bx", quote end, quote true end) 
	@T16("jz .+20", :(old_ip = @IP()), :(@IP() == (old_ip + 20) % UInt16))

	@T16(".byte 0x05,0x12,0x34", quote end, quote true end)  # add AX, IZ
	@T16("cmp ax, bx", quote end, quote true end) 
	@T16("je .+20", :(old_ip = @IP()), :(@IP() == (old_ip + 2) % UInt16 ))

	@T16(".byte 0xb8,0xfe,0xff", quote end, quote true end)  # mov AX, 0xfffe
	@T16("mov ss, ax", quote end, quote @sreg_base(cpu, SS) == UInt64(0xfffe0) end)

	println("OK")
end

main()

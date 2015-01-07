module JIA32
	const RAX_type = Uint64; const RAX_seq = 0; 
	const EAX_type = Uint32; const EAX_seq = 0;
	const AX_type  = Uint16; const AX_seq  = 0;
	const AL_type  = Uint16; const AL_seq  = 0;
	
	const RCX_type = Uint64; const RCX_seq = 1; 
	const ECX_type = Uint32; const ECX_seq = 1;
	const CX_type  = Uint16; const CX_seq  = 1;
	const CL_type  = Uint16; const CL_seq  = 1;
	
	const RDX_type = Uint64; const RDX_seq = 2; 
	const EDX_type = Uint32; const EDX_seq = 2;
	const DX_type  = Uint16; const DX_seq  = 2;
	const DL_type  = Uint16; const DL_seq  = 2;

	const RBX_type = Uint64; const RBX_seq = 3; 
	const EBX_type = Uint32; const EBX_seq = 3;
	const BX_type  = Uint16; const BX_seq  = 3;
	const BL_type  = Uint16; const BL_seq  = 3;

	const RSP_type = Uint64; const RSP_seq = 4; 
	const ESP_type = Uint32; const ESP_seq = 4;
	const SP_type  = Uint16; const SP_seq  = 4;

	const RBP_type = Uint64; const RBP_seq = 5; 
	const EBP_type = Uint32; const EBP_seq = 5;
	const BP_type  = Uint16; const BP_seq  = 5;

	const RSI_type = Uint64; const RSI_seq = 6; 
	const ESI_type = Uint32; const ESI_seq = 6;
	const SI_type  = Uint16; const SI_seq  = 6;

	const RDI_type = Uint64; const RDI_seq = 7; 
	const EDI_type = Uint32; const EDI_seq = 7;
	const DI_type  = Uint16; const DI_seq  = 7;

	type CPU
		genl_regs_buffer:: Array{Uint8}
		genl_regs:: Ptr{Uint8}

		type MMU
		end
	
		function CPU()
			cpu = new()
			# 16 64-bit general-purpose registers
			cpu.genl_regs_buffer = Array(Uint8, 16 * 8)
			cpu.genl_regs = cpu.genl_regs_buffer
			println(cpu.genl_regs)
			return cpu
		end

	end

#=
	macro def_genl_regs_get(rname, seq, width)
		return esc(quote
			@inline function $(symbol("get_$rname"))(cpu:: CPU)
				return unsafe_load(convert(Ptr{$width}, cpu.genl_regs + $seq * 8), 1);
			end
		end)
	end

	@def_genl_regs_get(rax, 0, Uint64)
	@def_genl_regs_get(eax, 0, Uint32)
	@def_genl_regs_get(ax, 0, Uint16)
	@def_genl_regs_get(al, 0, Uint8)
	@def_genl_regs_get(rcx, 1, Uint64)
	@def_genl_regs_get(ecx, 1, Uint32)
	@def_genl_regs_get(cx, 1, Uint16)
	@def_genl_regs_get(cl, 1, Uint8)
=#

	macro set_reg(cpu, width, seq, data)
		return :(unsafe_store!(convert(Ptr{$width}, $cpu.genl_regs + $seq * 8), $data, 1))
	end

	macro set_reg_named(cpu, reg, data)
		return :(@set_reg($cpu, $(symbol("$reg" * "_type")), $(symbol("$reg" * "_seq")), $data))
	end

	macro get_reg(cpu, width, seq)
		return :(unsafe_load(convert(Ptr{$width}, $cpu.genl_regs + $seq * 8), 1))
	end

	macro get_reg_named(cpu, reg)
		return :(@get_reg($cpu, $(symbol("$reg" * "_type")), $(symbol("$reg" * "_seq"))))
	end

	# ------------------- Testing -----------------------------
	function dummy(cpu:: CPU)
		@get_reg_named(cpu, RAX)
	end

	function dummy2(cpu:: CPU)
		@get_reg_named(cpu, BX)
	end

	function dummy3(cpu:: CPU, r:: Int)
		@get_reg(cpu, Uint64, r)
	end

	function dummy4(cpu:: CPU)
		@set_reg_named(cpu, RAX, 0x1234567887654321)
	end

	function dummy5(cpu:: CPU)
		@set_reg_named(cpu, EAX, 0x12345678)
	end

	function dummy6(cpu:: CPU, r:: Int, data:: Uint64)
		@set_reg(cpu, Uint64, r, data)
	end

	function dummy7(cpu:: CPU)
		@set_reg_named(cpu, RCX, @get_reg_named(cpu, RAX)) 
	end

	# Unit testing
	if (length(ARGS) > 0) && ARGS[1] == "test"
		cpu = JIA32.CPU()
		i = 3
 
		@code_native(dummy(cpu))
		println()
		@code_native(dummy2(cpu))
		println()
		@code_native(dummy3(cpu, i))
		println()
		@code_native(dummy4(cpu))
		println()
		@code_native(dummy5(cpu))
		println()
		@code_native(dummy6(cpu, i, 0x1234567887654321))
		println()
		@code_native(dummy7(cpu))
		println()

		# Test r/w
                print("Testing r/w functions ... ")
		@set_reg_named(cpu, RAX, 0x1234567887654321)
		if @get_reg_named(cpu, EAX) != uint32(0x87654321)
			error("EAX should be 0x87654321 after RAX <- 0x1234567887654321")
                end
		if @get_reg_named(cpu, AX) != uint16(0x4321)
			error("AX should be 0x4321 after RAX <- 0x1234567887654321")
                end

		@set_reg_named(cpu, EAX, 0xDEADBEEF)
		if @get_reg_named(cpu, RAX) != uint64(0x12345678deadbeef)
			error("RAX should be 0x12345678deadbeef after EAX <- 0xDEADBEEF")
                end
		println("OK")

	end
end

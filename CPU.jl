module JIA32
	const RAX_type = Uint64; const RAX_seq = 0; 
	const EAX_type = Uint32; const EAX_seq = 0;
	const AX_type  = Uint16; const AX_seq  = 0;
	const AL_type  = Uint8; const AL_seq  = 0;
	
	const RCX_type = Uint64; const RCX_seq = 1; 
	const ECX_type = Uint32; const ECX_seq = 1;
	const CX_type  = Uint16; const CX_seq  = 1;
	const CL_type  = Uint8; const CL_seq  = 1;
	
	const RDX_type = Uint64; const RDX_seq = 2; 
	const EDX_type = Uint32; const EDX_seq = 2;
	const DX_type  = Uint16; const DX_seq  = 2;
	const DL_type  = Uint8; const DL_seq  = 2;

	const RBX_type = Uint64; const RBX_seq = 3; 
	const EBX_type = Uint32; const EBX_seq = 3;
	const BX_type  = Uint16; const BX_seq  = 3;
	const BL_type  = Uint8; const BL_seq  = 3;

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

	const RIP_type = Uint64; const RIP_seq = 16;
	const EIP_type = Uint32; const EIP_seq = 16;

	type CPU
		genl_regs_buffer:: Array{Uint8}
		genl_regs:: Ptr{Uint8}
		cs:: Uint16; cs_base:: Uint64
		ds:: Uint16; ds_base:: Uint64
		es:: Uint16; es_base:: Uint64
		ss:: Uint16; ss_base:: Uint64
		fs:: Uint16; fs_base:: Uint64
		gs:: Uint16; gs_base:: Uint64
		rflag:: Uint64

		type MMU
		end
	
		# Constructor
		function CPU()
			cpu = new()

			# 16 64-bit general-purpose registers and instruction pointer
			cpu.genl_regs_buffer = Array(Uint8, 16 * 8 + 8)
			cpu.genl_regs = cpu.genl_regs_buffer

			return cpu
		end
	end

	# General register access functions
	macro reg_w!(cpu, width, seq, data)
		return :(unsafe_store!(convert(Ptr{$width}, $cpu.genl_regs + $seq * 8), $data, 1))
	end

	macro reg_w_named!(cpu, reg, data)
		return :(@reg_w!($cpu, $(symbol("$reg" * "_type")), $(symbol("$reg" * "_seq")), $data))
	end

	macro reg_w64!(cpu, reg, data)
		return :(@reg_w!($cpu, Uint64, $(symbol("$reg" * "_seq")), $data))
	end

	macro reg_w32!(cpu, reg, data)
		return :(@reg_w!($cpu, Uint32, $(symbol("$reg" * "_seq")), $data))
	end

	macro reg_w16!(cpu, reg, data)
		return :(@reg_w!($cpu, Uint16, $(symbol("$reg" * "_seq")), $data))
	end

	macro reg_r(cpu, width, seq)
		return :(unsafe_load(convert(Ptr{$width}, $cpu.genl_regs + $seq * 8), 1))
	end

	macro reg_r_named(cpu, reg)
		return :(@reg_r($cpu, $(symbol("$reg" * "_type")), $(symbol("$reg" * "_seq"))))
	end

	macro reg_r64(cpu, reg)
		return :(@reg_r($cpu, Uint64, $(symbol("$reg" * "_seq"))))
	end

	macro reg_r32(cpu, reg)
		return :(@reg_r($cpu, Uint32, $(symbol("$reg" * "_seq"))))
	end

	macro reg_r16(cpu, reg)
		return :(@reg_r($cpu, Uint16, $(symbol("$reg" * "_seq"))))
	end

	# Instruction pointer access function
	macro rip(cpu)
		return :(@reg_r_named($cpu, RIP))
	end

	macro rip!(cpu, data)
		return :(@reg_w_named!($cpu, RIP, $data))
	end

	macro rip_add!(cpu, addend)
		return :(@rip!($cpu, @rip($cpu) + $addend))
	end

	macro eip(cpu)
		return :(@reg_r_named($cpu, EIP))
	end

	macro eip!(cpu, data)
		return :(@reg_w_named!($cpu, EIP, $data))
	end
	
	macro eip_add!(cpu, addend)
		return :(@eip!($cpu, @eip($cpu) + $addend))
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


	# ------------------- Testing -----------------------------
	function dummy(cpu:: CPU)
		@reg_r_named(cpu, RAX)
	end

	function dummy2(cpu:: CPU)
		@reg_r_named(cpu, BX)
	end

	function dummy3(cpu:: CPU, r:: Int)
		@reg_r(cpu, Uint64, r)
	end

	function dummy4(cpu:: CPU)
		@reg_w_named!(cpu, RAX, 0x1234567887654321)
	end

	function dummy5(cpu:: CPU)
		@reg_w_named!(cpu, EAX, 0x12345678)
	end

	function dummy6(cpu:: CPU, r:: Int, data:: Uint64)
		@reg_w!(cpu, Uint64, r, data)
	end

	function dummy7(cpu:: CPU)
		@reg_w_named!(cpu, RCX, @reg_r_named(cpu, RAX))
	end

	function dummy8(cpu:: CPU)
		@reg_w32!(cpu, RCX, @reg_r32(cpu, RDX))
	end

	function dummy9(cpu:: CPU)
		@reg_w64!(cpu, RCX, uint64(@reg_r32(cpu, RDX)))
	end
	# Unit testing
	if (length(ARGS) > 0) && ARGS[1] == "test"
		cpu = JIA32.CPU()

		println(macroexpand(:@reg_w32!(cpu, RCX, @reg_r32(cpu, RAX))))
		# Show generated code
		i = 3
		if (rand(1:10) % 3 == 0)
			t = Uint64
		else
			t = Uint32
		end
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
		@code_native(dummy8(cpu))
		println()
		@code_native(dummy9(cpu))
		println()

		# Testing r/w
                print("Testing r/w functions ... ")
		@reg_w_named!(cpu, RAX, 0x1234567887654321)
		if @reg_r_named(cpu, EAX) != uint32(0x87654321)
			error("EAX should be 0x87654321 after RAX <- 0x1234567887654321")
                end
		if @reg_r_named(cpu, AX) != uint16(0x4321)
			error("AX should be 0x4321 after RAX <- 0x1234567887654321")
                end

		@reg_w_named!(cpu, EAX, 0xDEADBEEF)
		if @reg_r_named(cpu, RAX) != uint64(0x12345678deadbeef)
			error("RAX should be 0x12345678deadbeef after EAX <- 0xDEADBEEF")
                end

		@reg_w_named!(cpu, RCX, @reg_r_named(cpu, RAX))
		if @reg_r_named(cpu, RCX) != uint64(0x12345678deadbeef)
			error("RCX should be 0x12345678deadbeef after RCX <- RAX")
		end

		@reg_w_named!(cpu, CL, 0xAA)
		if @reg_r_named(cpu, CX) != uint16(0xbeaa)
			error("CX should be 0xbeaa after CL <- 0xaa")
		end

		@reg_w64!(cpu, RDI, @reg_r64(cpu, RAX))
		if @reg_r64(cpu, RDI) != @reg_r64(cpu, RAX)
			error("RDI should equal to RAX after RDI<-RAX")
		end

		# Testing RIP
		@rip!(cpu, 0xffffffffffff0000)
		if @rip(cpu) != 0xffffffffffff0000
			error("RIP should be 0xffffffffffff0000")
		end
		if @eip(cpu) != 0xffff0000
			error("EIP should be 0xffff0000")
		end
		@eip!(cpu, 0x13572468)
		if @rip(cpu) != 0xffffffff13572468
			error("RIP should be 0xffffffff13572468")
		end

		println("OK")
	end
end

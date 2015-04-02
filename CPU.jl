include("PhysicalMemory.jl")

const RAX_type = UInt64; const RAX_seq = 0; 
const EAX_type = UInt32; const EAX_seq = 0;
const AX_type  = UInt16; const AX_seq  = 0;
const AL_type  = UInt8; const AL_seq  = 0;

const RCX_type = UInt64; const RCX_seq = 1; 
const ECX_type = UInt32; const ECX_seq = 1;
const CX_type  = UInt16; const CX_seq  = 1;
const CL_type  = UInt8; const CL_seq  = 1;

const RDX_type = UInt64; const RDX_seq = 2; 
const EDX_type = UInt32; const EDX_seq = 2;
const DX_type  = UInt16; const DX_seq  = 2;
const DL_type  = UInt8; const DL_seq  = 2;

const RBX_type = UInt64; const RBX_seq = 3; 
const EBX_type = UInt32; const EBX_seq = 3;
const BX_type  = UInt16; const BX_seq  = 3;
const BL_type  = UInt8; const BL_seq  = 3;

const RSP_type = UInt64; const RSP_seq = 4; 
const ESP_type = UInt32; const ESP_seq = 4;
const SP_type  = UInt16; const SP_seq  = 4;

const RBP_type = UInt64; const RBP_seq = 5; 
const EBP_type = UInt32; const EBP_seq = 5;
const BP_type  = UInt16; const BP_seq  = 5;

const RSI_type = UInt64; const RSI_seq = 6; 
const ESI_type = UInt32; const ESI_seq = 6;
const SI_type  = UInt16; const SI_seq  = 6;

const RDI_type = UInt64; const RDI_seq = 7; 
const EDI_type = UInt32; const EDI_seq = 7;
const DI_type  = UInt16; const DI_seq  = 7;

const RIP_type = UInt64; const RIP_seq = 16;
const EIP_type = UInt32; const EIP_seq = 16;
const IP_type = UInt16; const IP_seq = 16;

const CS = 0
const DS = 1
const ES = 2
const SS = 3
const FS = 4
const GS = 5

type CPU
	genl_regs_buffer:: Array{UInt8}
	genl_regs:: Ptr{UInt8}
	seg_regs_buffer:: Array{UInt16}
	seg_regs:: Ptr{UInt16}
	seg_shadow_regs_buffer:: Array{UInt64}
	seg_shadow_regs:: Ptr{UInt64}
	rflag:: UInt64

	# Internal use
	docoding_rip:: UInt64
	decoding_eip:: UInt32
	decoding_ip:: UInt16

	# Constructor
	function CPU()
		cpu = new()

		# 16 64-bit general-purpose registers and instruction pointer
		cpu.genl_regs_buffer = Array(UInt8, 16 * 8 + 8)
		cpu.genl_regs = pointer(cpu.genl_regs_buffer)

		# 6 16-bit segment register and their hidden parts
		cpu.seg_regs_buffer = Array(UInt16, 6)
		cpu.seg_regs = pointer(cpu.seg_regs_buffer)
		cpu.seg_shadow_regs_buffer = Array(UInt64, 6)
		cpu.seg_shadow_regs = pointer(cpu.seg_shadow_regs_buffer)

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

@def_genl_regs_get(rax, 0, UInt64)
@def_genl_regs_get(eax, 0, UInt32)
@def_genl_regs_get(ax, 0, UInt16)
@def_genl_regs_get(al, 0, UInt8)
@def_genl_regs_get(rcx, 1, UInt64)
@def_genl_regs_get(ecx, 1, UInt32)
@def_genl_regs_get(cx, 1, UInt16)
@def_genl_regs_get(cl, 1, UInt8)
=#

# General register access functions
macro reg_w!(cpu, width, seq, data)
	return :(unsafe_store!(convert(Ptr{$width}, $cpu.genl_regs + $seq * 8), $data, 1))
end

macro reg_w_named!(cpu, reg, data)
	return :(@reg_w!($cpu, $(symbol("$reg" * "_type")), $(symbol("$reg" * "_seq")), $data))
end

macro reg_w64!(cpu, reg, data)
	return :(@reg_w!($cpu, UInt64, $(symbol("$reg" * "_seq")), $data))
end

macro reg_w32!(cpu, reg, data)
	return :(@reg_w!($cpu, UInt32, $(symbol("$reg" * "_seq")), $data))
end

macro reg_w16!(cpu, reg, data)
	return :(@reg_w!($cpu, UInt16, $(symbol("$reg" * "_seq")), $data))
end

macro reg_r(cpu, width, seq)
	return :(unsafe_load(convert(Ptr{$width}, $cpu.genl_regs + $seq * 8), 1))
end

macro reg_r_named(cpu, reg)
	return :(@reg_r($cpu, $(symbol("$reg" * "_type")), $(symbol("$reg" * "_seq"))))
end

macro reg_r64(cpu, reg)
	return :(@reg_r($cpu, UInt64, $(symbol("$reg" * "_seq"))))
end

macro reg_r32(cpu, reg)
	return :(@reg_r($cpu, UInt32, $(symbol("$reg" * "_seq"))))
end

macro reg_r16(cpu, reg)
	return :(@reg_r($cpu, UInt16, $(symbol("$reg" * "_seq"))))
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

macro ip(cpu)
	return :(@reg_r_named($cpu, IP))
end

macro ip!(cpu, data)
	return :(@reg_w_named!($cpu, IP, $data))
end

macro ip_add!(cpu, addend)
	return :(@ip!($cpu, @ip($cpu) + $addend))
end

# Segment register access function
macro sreg!(cpu, seq, data)
	return :(unsafe_store!(convert(Ptr{UInt16}, $cpu.seg_regs + $seq * 2), $data, 1))
end

macro sreg(cpu, seq)
	return :(unsafe_load(convert(Ptr{UInt16}, $cpu.seg_regs + $seq * 2), 1))
end

macro sreg_shadow!(cpu, seq, data)
	return :(unsafe_store!(convert(Ptr{UInt64}, $cpu.seg_shadow_regs + $seq * 8), $data, 1))
end

macro sreg_shadow(cpu, seq)
	return :(unsafe_load(convert(Ptr{UInt64}, $cpu.seg_shadow_regs + $seq * 8), 1))
end

# MMU functions

@noinline function logical_to_linear_real_mode(cpu:: CPU, seg:: Int, offset:: UInt16)
	return UInt64((@sreg_shadow(cpu, seg) & 0xffffffff) + offset)
end

@noinline function logical_to_linear(cpu:: CPU, seg:: Int, offset:: UInt64)
	if true # Condition to fetch instruction in real mode
		return UInt64(logical_to_linear_real_mode(cpu, seg, UInt16(offset & 0xffff)))
	end
end

function ru64_crosspg(cpu:: CPU, mem:: PhysicalMemory, seg:: Int, offset:: UInt64)
	ret = UInt64(0)
	for i = 0 : 7
		ret += (UInt64(phys_read_u8(mem, logical_to_linear(cpu, seg, offset + i))) << (i << 3))
	end
	return ret
end

@noinline function ru64_fast(cpu:: CPU, mem:: PhysicalMemory, seg:: Int, offset:: UInt64)
	phys_addr = logical_to_linear(cpu, seg, offset)
	return phys_read_u64(mem, phys_addr)
end

function ru64(cpu:: CPU, mem:: PhysicalMemory, seg:: Int, offset:: UInt64)
	if ((offset + 7) $ offset) & (~UInt64(0xfff)) == 0
		# In the same page
		return ru64_fast(cpu, mem, seg, offset)
	else
		# Cross-page access
		return ru64_crosspg(cpu, mem, seg, offset)
	end
	
end
function rs64(cpu:: CPU, seg:: Int, offset:: UInt64)
end
function ru32(cpu:: CPU, seg:: Int, offset:: UInt64)
end
function rs32(cpu:: CPU, seg:: Int, offset:: UInt64)
end
function ru16(cpu:: CPU, seg:: Int, offset:: UInt64)
end
function rs16(cpu:: CPU, seg:: Int, offset:: UInt64)
end
function ru8(cpu:: CPU, seg:: Int, offset:: UInt64)
end
function rs8(cpu:: CPU, seg:: Int, offset:: UInt64)
end



# CPU functions
function loop(cpu:: CPU)
	while true
		cpu.decoding_rip = @rip(cpu)
		cpu.decoding_eip = @eip(cpu)
		execute(fetch_op_byte())
	end
end


function reset(cpu:: CPU)
	@rip!(cpu, 0x000000000000FFF0)
	@sreg!(cpu, CS, 0xF000)
	@sreg_shadow!(cpu, CS, 0xFFFF0000)
	@sreg!(cpu, DS, 0)
	@sreg_shadow!(cpu, DS, 0x0)
	@sreg!(cpu, ES, 0)
	@sreg_shadow!(cpu, ES, 0x0)
	@sreg!(cpu, SS, 0)
	@sreg_shadow!(cpu, SS, 0x0)
	@reg_w_named!(cpu, RSP, 0)
end


# ------------------- Testing -----------------------------
function dummy(cpu:: CPU)
	@reg_r_named(cpu, RAX)
end

function dummy2(cpu:: CPU)
	@reg_r_named(cpu, BX)
end

function dummy3(cpu:: CPU, r:: Int)
	@reg_r(cpu, UInt64, r)
end

function dummy4(cpu:: CPU)
	@reg_w_named!(cpu, RAX, 0x1234567887654321)
end

function dummy5(cpu:: CPU)
	@reg_w_named!(cpu, EAX, 0x12345678)
end

function dummy6(cpu:: CPU, r:: Int, data:: UInt64)
	@reg_w!(cpu, UInt64, r, data)
end

function dummy7(cpu:: CPU)
	@reg_w_named!(cpu, RCX, @reg_r_named(cpu, RAX))
end

function dummy8(cpu:: CPU)
	@reg_w32!(cpu, RCX, @reg_r32(cpu, RDX))
end

function dummy9(cpu:: CPU)
	@reg_w64!(cpu, RCX, UInt64(@reg_r32(cpu, RDX)))
end

# Unit testing
if (length(ARGS) > 0) && ARGS[1] == "test"
	mem = PhysicalMemory(UInt64(4096*1024))
	cpu = CPU()
	reset(cpu)

	println(macroexpand(:@reg_w32!(cpu, RCX, @reg_r32(cpu, RAX))))
	# Show generated code
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
	@code_native(dummy8(cpu))
	println()
	@code_native(dummy9(cpu))
	println()
	@code_native(logical_to_linear(cpu, 0, UInt64(0x1234)))
	println()
	@code_native(ru64(cpu, mem, 0, UInt64(0x1234)))
	println()
	@code_native(ru64_fast(cpu, mem, 0, UInt64(0x1234)))
	println()

	# Testing r/w
	print("Testing r/w functions ... ")
	@reg_w_named!(cpu, RAX, 0x1234567887654321)
	if @reg_r_named(cpu, EAX) != UInt32(0x87654321)
		error("EAX should be 0x87654321 after RAX <- 0x1234567887654321")
	end
	if @reg_r_named(cpu, AX) != UInt16(0x4321)
		error("AX should be 0x4321 after RAX <- 0x1234567887654321")
	end

	@reg_w_named!(cpu, EAX, 0xDEADBEEF)
	if @reg_r_named(cpu, RAX) != UInt64(0x12345678deadbeef)
		error("RAX should be 0x12345678deadbeef after EAX <- 0xDEADBEEF")
	end

	@reg_w_named!(cpu, RCX, @reg_r_named(cpu, RAX))
	if @reg_r_named(cpu, RCX) != UInt64(0x12345678deadbeef)
		error("RCX should be 0x12345678deadbeef after RCX <- RAX")
	end

	@reg_w_named!(cpu, CL, 0xAA)
	if @reg_r_named(cpu, CX) != UInt16(0xbeaa)
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


	ru64(cpu, mem, DS, UInt64(0xff0))
	println("OK")
end

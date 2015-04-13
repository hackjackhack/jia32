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
	rflag:: UInt64

	# Internal use
	seg_regs_base_buffer:: Array{UInt64}
	seg_regs_base:: Ptr{UInt64}

	operand_size:: Int
	address_size:: Int

	decoding_rip:: UInt64
	decoding_eip:: UInt32
	decoding_ip:: UInt16

	emu_insn_tbl:: Dict{UInt32, Function}
	jit_insn_tbl:: Dict{UInt32, Function}

	jit_enabled:: Bool
	jit_rip:: UInt64
	jit_eot:: Bool
	jl_blocks:: Dict{UInt64, Dict{UInt64, Function}}

	# Constructor
	function CPU(phys_mem_size:: UInt64)
		cpu = new()

		# 16 64-bit general-purpose registers and instruction pointer
		cpu.genl_regs_buffer = Array(UInt8, 16 * 8 + 8)
		cpu.genl_regs = pointer(cpu.genl_regs_buffer)

		# 6 16-bit segment register and their hidden parts
		cpu.seg_regs_buffer = Array(UInt16, 6)
		cpu.seg_regs = pointer(cpu.seg_regs_buffer)
		cpu.seg_regs_base_buffer = Array(UInt64, 6)
		cpu.seg_regs_base = pointer(cpu.seg_regs_base_buffer)

		cpu.operand_size = 16
		cpu.address_size = 16
		cpu.emu_insn_tbl = Dict{UInt32, Function}()
		cpu.jit_insn_tbl = Dict{UInt32, Function}()

		cpu.jit_enabled = true
		cpu.jl_blocks = Dict{UInt64, Dict{UInt64, Function}}()

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
	return :(@rip!($cpu, (@rip($cpu) + $addend) & 0xffffffffffffffff))
end

macro eip(cpu)
	return :(@reg_r_named($cpu, EIP))
end

macro eip!(cpu, data)
	return :(@reg_w_named!($cpu, EIP, $data))
end

macro eip_add!(cpu, addend)
	return :(@eip!($cpu, (@eip($cpu) + $addend) & 0xffffffff))
end

macro ip(cpu)
	return :(@reg_r_named($cpu, IP))
end

macro ip!(cpu, data)
	return :(@reg_w_named!($cpu, IP, $data))
end

macro ip_add!(cpu, addend)
	return :(@ip!($cpu, (@ip($cpu) + $addend) & 0xffff))
end

# Segment register access function
macro sreg!(cpu, seq, data)
	return :(unsafe_store!(convert(Ptr{UInt16}, $cpu.seg_regs + $seq * 2), $data, 1))
end

macro sreg(cpu, seq)
	return :(unsafe_load(convert(Ptr{UInt16}, $cpu.seg_regs + $seq * 2), 1))
end

macro sreg_base!(cpu, seq, data)
	return :(unsafe_store!(convert(Ptr{UInt64}, $cpu.seg_regs_base + $seq * 8), $data, 1))
end

macro sreg_base(cpu, seq)
	return :(unsafe_load(convert(Ptr{UInt64}, $cpu.seg_regs_base + $seq * 8), 1))
end

# MMU functions
# Vol. 1, Chapter 3.3.1 & Fig. 3-3
@noinline function logical_to_physical_real_mode(cpu:: CPU, seg:: Int, offset:: UInt16)
	return UInt64((@sreg_base(cpu, seg) & 0xffffffff) + offset)
end

@noinline function logical_to_physical(cpu:: CPU, seg:: Int, offset:: UInt64)
	if true # Condition to fetch instruction in real mode
		return UInt64(logical_to_physical_real_mode(cpu, seg, UInt16(offset & 0xffff)))
	end
end

# -----64-----
function ru64_crosspg(cpu:: CPU, mem:: PhysicalMemory, seg:: Int, offset:: UInt64)
	ret = UInt64(0)
	for i = 0 : 7
		ret += (UInt64(phys_read_u8(mem, logical_to_physical(cpu, seg, offset + i))) << (i << 3))
	end
	return ret
end

@noinline function ru64_fast(cpu:: CPU, mem:: PhysicalMemory, seg:: Int, offset:: UInt64)
	phys_addr = logical_to_physical(cpu, seg, offset)
	return phys_read_u64(mem, phys_addr)
end

function ru64(cpu:: CPU, mem:: PhysicalMemory, seg:: Int, offset:: UInt64)
	#if ((offset + 7) $ offset) & (~UInt64(0xfff)) == 0
	if (offset & (UInt64(0xfff))) < 4089
		# In the same page
		return ru64_fast(cpu, mem, seg, offset)
	else
		# Cross-page access
		return ru64_crosspg(cpu, mem, seg, offset)
	end
end

@inline function rs64(cpu:: CPU, mem:: PhysicalMemory, seg:: Int, offset:: UInt64)
	return reinterpret(Int64, ru64(cpu, mem, seg, offset))
end

# -----32-----
function ru32_crosspg(cpu:: CPU, mem:: PhysicalMemory, seg:: Int, offset:: UInt64)
	ret = UInt32(0)
	for i = 0 : 3
		ret += (UInt32(phys_read_u8(mem, logical_to_physical(cpu, seg, offset + i))) << (i << 3))
	end
	return ret
end

@noinline function ru32_fast(cpu:: CPU, mem:: PhysicalMemory, seg:: Int, offset:: UInt64)
	phys_addr = logical_to_physical(cpu, seg, offset)
	return phys_read_u32(mem, phys_addr)
end

function ru32(cpu:: CPU, mem:: PhysicalMemory, seg:: Int, offset:: UInt64)
	#if ((offset + 3) $ offset) & (~UInt64(0xfff)) == 0
	if (offset & (UInt64(0xfff))) < 4093
		# In the same page
		return ru32_fast(cpu, mem, seg, offset)
	else
		# Cross-page access
		return ru32_crosspg(cpu, mem, seg, offset)
	end
end

@inline function rs32(cpu:: CPU, mem:: PhysicalMemory, seg:: Int, offset:: UInt64)
	return reinterpret(Int32, ru32(cpu, mem, seg, offset))
end

#-----16-----
function ru16_crosspg(cpu:: CPU, mem:: PhysicalMemory, seg:: Int, offset:: UInt64)
	ret = UInt16(0)
	for i = 0 : 1
		ret += (UInt16(phys_read_u8(mem, logical_to_physical(cpu, seg, offset + i))) << (i << 3))
	end
	return ret
end

@noinline function ru16_fast(cpu:: CPU, mem:: PhysicalMemory, seg:: Int, offset:: UInt64)
	phys_addr = logical_to_physical(cpu, seg, offset)
	return phys_read_u16(mem, phys_addr)
end

function ru16(cpu:: CPU, mem:: PhysicalMemory, seg:: Int, offset:: UInt64)
	if (offset & (UInt64(0xfff))) < 4095
		# In the same page
		return ru16_fast(cpu, mem, seg, offset)
	else
		# Cross-page access
		return ru16_crosspg(cpu, mem, seg, offset)
	end
end

@inline function rs16(cpu:: CPU, mem:: PhysicalMemory, seg:: Int, offset:: UInt64)
	return reinterpret(Int16, ru16(cpu, mem, seg, offset))
end

#-----8-----
function ru8(cpu:: CPU, mem:: PhysicalMemory, seg:: Int, offset:: UInt64)
	phys_addr = logical_to_physical(cpu, seg, offset)
	return phys_read_u8(mem, phys_addr)
end
function rs8(cpu:: CPU, mem:: PhysicalMemory, seg:: Int, offset:: UInt64)
	return reinterpret(Int8, ru8(cpu, mem, seg, offset))
end

# Execution engine

require("Instructions.jl")

# CPU functions
function loop(cpu:: CPU, mem:: PhysicalMemory)
	local b:: UInt8
	while true
		println(hex(@sreg(cpu, CS)))
		println(hex(@sreg_base(cpu, CS)))
		println(hex(@eip(cpu)))
		

		if cpu.jit_enabled
			f = find_jl_block(cpu, mem)
			f(cpu, mem)
		else
			b = emu_fetch8_advance(cpu, mem)
			println(hex(b))
			cpu.emu_insn_tbl[b](cpu, mem)
		end
	end
end

function reset(cpu:: CPU)
	# Volume 3, Chapter 9.1.4 First instruction executed.
	# Volume 3, Chapter 9.10, Fig 9-3
	@rip!(cpu, 0x000000000000FFF0)
	@sreg!(cpu, CS, 0xF000)
	@sreg_base!(cpu, CS, 0xFFFF0000)
	@sreg!(cpu, DS, 0)
	@sreg_base!(cpu, DS, 0x0)
	@sreg!(cpu, ES, 0)
	@sreg_base!(cpu, ES, 0x0)
	@sreg!(cpu, SS, 0)
	@sreg_base!(cpu, SS, 0x0)
	@reg_w_named!(cpu, RSP, 0)
end



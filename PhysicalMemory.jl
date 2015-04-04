include("hw/MMIO.jl")

type TestDev <: MMIO
	base:: UInt64
	state:: Int
end

type PhysicalMemory
	size:: UInt64
	array:: Array{UInt8}
	baseptr:: Ptr{UInt8}
	iomap:: Array{Bool}
	iomap_dev:: Array{MMIO}
	iomap_r64:: Array{Function}
	iomap_r32:: Array{Function}
	iomap_r16:: Array{Function}
	iomap_r8:: Array{Function}
	iomap_w64:: Array{Function}
	iomap_w32:: Array{Function}
	iomap_w16:: Array{Function}
	iomap_w8:: Array{Function}

	function PhysicalMemory(size:: UInt64)
		# Extra space for buggy manipulation on the last word
		# (This should never happen since MMU will performance 
		# boundary check before accessing physical memory.) 
		m = new(size,
			Array(UInt8, size + 4096),
			0,
			Array(Bool, (size + 4096) >>> 12 ),
			Array(MMIO, (size + 4096) >>> 12 ),
			Array(Function, (size + 4096) >>> 12),
			Array(Function, (size + 4096) >>> 12),
			Array(Function, (size + 4096) >>> 12),
			Array(Function, (size + 4096) >>> 12),
			Array(Function, (size + 4096) >>> 12),
			Array(Function, (size + 4096) >>> 12),
			Array(Function, (size + 4096) >>> 12),
			Array(Function, (size + 4096) >>> 12),
			)
		fill!(m.array, 0)
		fill!(m.iomap, false)
		
		m.baseptr = convert(Ptr{UInt8}, pointer(m.array))

		return m
	end
end

function register_phys_io_map(
	memory:: PhysicalMemory, start:: UInt64, size:: UInt64,
	device:: MMIO,
	f_r64:: Function, f_r32:: Function, f_r16:: Function, f_r8:: Function,
	f_w64:: Function, f_w32:: Function, f_w16:: Function, f_w8:: Function)

	if (((start | size) & 0xfff) != 0)
		error("start and size must be page-aligned")
	end
	for i = (start >>> 12) + 1 : ((start + size) >>> 12)
		memory.iomap[i] = true
		memory.iomap_dev[i] = device
		memory.iomap_r64[i] = f_r64
		memory.iomap_r32[i] = f_r32
		memory.iomap_r16[i] = f_r16
		memory.iomap_r8[i] = f_r8
		memory.iomap_w64[i] = f_w64
		memory.iomap_w32[i] = f_w32
		memory.iomap_w16[i] = f_w16
		memory.iomap_w8[i] = f_w8
	end

	device.base = start
end

# The following R/W functions should be only called by MMU functions.
# E.g. ru64, ru43, wu64, etc. Therefore, it is assumed the cross-page
# case has been taken care by MMU functions. Never call these functions
# unless the above assumption is satisfied.

# Read access functions

# 64-bit 
@noinline function io_r64(memory:: PhysicalMemory, addr:: UInt64)
	seq = (addr >>> 12) + 1
	return memory.iomap_r64[seq](memory.iomap_dev[seq], addr)
end

@noinline function phys_read_u64(memory:: PhysicalMemory, addr:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		return unsafe_load(convert(Ptr{UInt64}, memory.baseptr + addr), 1)
	end
	return UInt64(io_r64(memory, addr))
end

#=
function phys_read_s64(memory:: PhysicalMemory, addr:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		return unsafe_load(convert(Ptr{Int64}, memory.baseptr + addr), 1)
	end
	return Int64(io_r64(memory, addr))
end
=#

# 32-bit
@noinline function io_r32(memory:: PhysicalMemory, addr:: UInt64)
	seq = (addr >>> 12) + 1
	return memory.iomap_r32[seq](memory.iomap_dev[seq], addr)
end

function phys_read_u32(memory:: PhysicalMemory, addr:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		return unsafe_load(convert(Ptr{UInt32}, memory.baseptr + addr), 1)
	end
	return UInt32(io_r32(memory, addr))
end

#=
function phys_read_s32(memory:: PhysicalMemory, addr:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		return unsafe_load(convert(Ptr{Int32}, memory.baseptr + addr), 1)
	end
	return Int32(io_r32(memory, addr))
end
=#

# 16-bit
@noinline function io_r16(memory:: PhysicalMemory, addr:: UInt64)
	seq = (addr >>> 12) + 1
	return memory.iomap_r16[seq](memory.iomap_dev[seq], addr)
end

function phys_read_u16(memory:: PhysicalMemory, addr:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		return unsafe_load(convert(Ptr{UInt16}, memory.baseptr + addr), 1);
	end
	return UInt16(io_r16(memory, addr))
end

#=
function phys_read_s16(memory:: PhysicalMemory, addr:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		return unsafe_load(convert(Ptr{Int16}, memory.baseptr + addr), 1);
	end
	return Int16(io_r16(memory, addr))
end
=#

# 8-bit
@noinline function io_r8(memory:: PhysicalMemory, addr:: UInt64)
	seq = (addr >>> 12) + 1
	return UInt8(memory.iomap_r8[seq](memory.iomap_dev[seq], addr))
end

function phys_read_u8(memory:: PhysicalMemory, addr:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		return unsafe_load(convert(Ptr{UInt8}, memory.baseptr + addr), 1);
	end
	return io_r8(memory, addr)
end

#=
function phys_read_s8(memory:: PhysicalMemory, addr:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		return unsafe_load(convert(Ptr{Int8}, memory.baseptr + addr), 1);
	end
	return reinterpret(Int8, io_r8(memory, addr))
end
=#

# Write access functions
# 64-bit 
@noinline function io_w64(memory:: PhysicalMemory, addr:: UInt64, data:: UInt64)
	seq = (addr >>> 12) + 1
	memory.iomap_w64[seq](memory.iomap_dev[seq], addr, data)
end

function phys_write_u64(memory:: PhysicalMemory, addr:: UInt64, data:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		unsafe_store!(convert(Ptr{UInt64}, memory.baseptr + addr), data, 1);
		return
	end
	io_w64(memory, addr, data)
end

#=
function phys_write_s64(memory:: PhysicalMemory, addr:: UInt64, data:: Int64)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		unsafe_store!(convert(Ptr{Int64}, memory.baseptr + addr), data, 1);
		return
	end
	io_w64(memory, addr, data)
end
=#

# 32-bit
@noinline function io_w32(memory:: PhysicalMemory, addr:: UInt64, data:: UInt32)
	seq = (addr >>> 12) + 1
	memory.iomap_w32[seq](memory.iomap_dev[seq], addr, data)
end

function phys_write_u32(memory:: PhysicalMemory, addr:: UInt64, data:: UInt32)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		unsafe_store!(convert(Ptr{UInt32}, memory.baseptr + addr), data, 1);
		return
	end
	io_w32(memory, addr, data)
end

#=
function phys_write_s32(memory:: PhysicalMemory, addr:: UInt64, data:: Int32)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		unsafe_store!(convert(Ptr{Int32}, memory.baseptr + addr), data, 1);
		return
	end
	io_w32(memory, addr, data)
end
=#

# 16-bit
@noinline function io_w16(memory:: PhysicalMemory, addr:: UInt64, data:: UInt16)
	seq = (addr >>> 12) + 1
	memory.iomap_w16[seq](memory.iomap_dev[seq], addr, data)
end

function phys_write_u16(memory:: PhysicalMemory, addr:: UInt64, data:: UInt16)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		unsafe_store!(convert(Ptr{UInt16}, memory.baseptr + addr), data, 1);
		return
	end
	io_w16(memory, addr, data)
end

#=
function phys_write_s16(memory:: PhysicalMemory, addr:: UInt64, data:: Int16)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		unsafe_store!(convert(Ptr{Int16}, memory.baseptr + addr), data, 1);
		return
	end
	io_w16(memory, addr, data)
end
=#

# 8-bit
@noinline function io_w8(memory:: PhysicalMemory, addr:: UInt64, data:: UInt8)
	seq = (addr >>> 12) + 1
	memory.iomap_w8[seq](memory.iomap_dev[seq], addr, data)
end

function phys_write_u8(memory:: PhysicalMemory, addr:: UInt64, data:: UInt8)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		unsafe_store!(convert(Ptr{UInt8}, memory.baseptr + addr), data, 1);
		return
	end
	io_w8(memory, addr, data)
end

#=
function phys_write_s8(memory:: PhysicalMemory, addr:: UInt64, data:: Int8)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		unsafe_store!(convert(Ptr{Int8}, memory.baseptr + addr), data, 1);
		return
	end
	io_w8(memory, addr, data)
end
=#


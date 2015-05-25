include("hw/IODev.jl")

const PAGE_BITS = 12
const PAGE_SIZE = (1 << PAGE_BITS)
const PAGE_MASK = UInt64((PAGE_SIZE - 1))

type PhysicalMemory
	size:: UInt64
	array:: Array{UInt8}
	baseptr:: Ptr{UInt8}

	#= Memory-mapped I/O : devices that can be
	   accessed through the processor’s physical-memory address space.
	   See Vol.1 16.3.1 =#
	iomap:: Array{Bool}
	iomap_dev:: Array{IODev}
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
			Array(UInt8, size + PAGE_SIZE),
			0,
			Array(Bool, 1 << 20),
			Array(IODev, 1 << 20),
			Array(Function, 1 << 20),
			Array(Function, 1 << 20),
			Array(Function, 1 << 20),
			Array(Function, 1 << 20),
			Array(Function, 1 << 20),
			Array(Function, 1 << 20),
			Array(Function, 1 << 20),
			Array(Function, 1 << 20),
			)
		fill!(m.array, 0)
		fill!(m.iomap, false)
		
		m.baseptr = convert(Ptr{UInt8}, pointer(m.array))
		println(m.baseptr)
		return m
	end
end

function register_phys_io_map(
	memory:: PhysicalMemory, start:: UInt64, size:: UInt64,
	device:: IODev,
	f_r64:: Function, f_r32:: Function, f_r16:: Function, f_r8:: Function,
	f_w64:: Function, f_w32:: Function, f_w16:: Function, f_w8:: Function)

	if (((start | size) & PAGE_MASK) != 0)
		error("start and size must be page-aligned")
	end
	for i = (start >>> PAGE_BITS) + 1 : ((start + size) >>> PAGE_BITS)
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
	seq = (addr >>> PAGE_BITS) + 1
	return memory.iomap_r64[seq](memory.iomap_dev[seq], addr)
end

@noinline function phys_read_u64(memory:: PhysicalMemory, addr:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> PAGE_BITS) + 1]
	if !isIO
		return unsafe_load(convert(Ptr{UInt64}, memory.baseptr + addr), 1)
	end
	return UInt64(io_r64(memory, addr))
end

# 32-bit
@noinline function io_r32(memory:: PhysicalMemory, addr:: UInt64)
	seq = (addr >>> PAGE_BITS) + 1
	return memory.iomap_r32[seq](memory.iomap_dev[seq], addr)
end

function phys_read_u32(memory:: PhysicalMemory, addr:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> PAGE_BITS) + 1]
	if !isIO
		return unsafe_load(convert(Ptr{UInt32}, memory.baseptr + addr), 1)
	end
	return UInt32(io_r32(memory, addr))
end

# 16-bit
@noinline function io_r16(memory:: PhysicalMemory, addr:: UInt64)
	seq = (addr >>> PAGE_BITS) + 1
	return memory.iomap_r16[seq](memory.iomap_dev[seq], addr)
end

function phys_read_u16(memory:: PhysicalMemory, addr:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> PAGE_BITS) + 1]
	if !isIO
		return unsafe_load(convert(Ptr{UInt16}, memory.baseptr + addr), 1);
	end
	return UInt16(io_r16(memory, addr))
end

# 8-bit
@noinline function io_r8(memory:: PhysicalMemory, addr:: UInt64)
	seq = (addr >>> PAGE_BITS) + 1
	return UInt8(memory.iomap_r8[seq](memory.iomap_dev[seq], addr))
end

function phys_read_u8(memory:: PhysicalMemory, addr:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> PAGE_BITS) + 1]
	if !isIO
		return unsafe_load(convert(Ptr{UInt8}, memory.baseptr + addr), 1);
	end
	return io_r8(memory, addr)
end

# Copy physical RAM into buffer
function phys_ram_to_buffer(addr:: UInt64, len:: UInt64, buf:: Ptr{UInt8})
	while len > 0
		@inbounds isIO = g_phys_mem.iomap[(addr >>> PAGE_BITS) + 1]
		if isIO
			unsafe_store!(buf, io_r8(g_phys_mem, addr), 1)
			len -= 1
			buf += 1
			addr += 1
		else
			l = min(((addr + PAGE_SIZE) & ~PAGE_MASK) - addr, len)
			ccall(("memcpy", "libc"), Ptr{Void}, (Ptr{Void}, Ptr{Void}, Csize_t,), buf, convert(Ptr{Void}, g_phys_mem.baseptr + addr), l)
			len -= l
			buf += l
			addr += l
		end
	end
end

# Write access functions
# 64-bit 
@noinline function io_w64(memory:: PhysicalMemory, addr:: UInt64, data:: UInt64)
	seq = (addr >>> PAGE_BITS) + 1
	memory.iomap_w64[seq](memory.iomap_dev[seq], addr, data)
end

function phys_write_u64(memory:: PhysicalMemory, addr:: UInt64, data:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> PAGE_BITS) + 1]
	if !isIO
		unsafe_store!(convert(Ptr{UInt64}, memory.baseptr + addr), data, 1);
		return
	end
	io_w64(memory, addr, data)
end

# 32-bit
@noinline function io_w32(memory:: PhysicalMemory, addr:: UInt64, data:: UInt32)
	seq = (addr >>> PAGE_BITS) + 1
	memory.iomap_w32[seq](memory.iomap_dev[seq], addr, data)
end

function phys_write_u32(memory:: PhysicalMemory, addr:: UInt64, data:: UInt32)
	@inbounds isIO = memory.iomap[(addr >>> PAGE_BITS) + 1]
	if !isIO
		unsafe_store!(convert(Ptr{UInt32}, memory.baseptr + addr), data, 1);
		return
	end
	io_w32(memory, addr, data)
end

# 16-bit
@noinline function io_w16(memory:: PhysicalMemory, addr:: UInt64, data:: UInt16)
	seq = (addr >>> PAGE_BITS) + 1
	memory.iomap_w16[seq](memory.iomap_dev[seq], addr, data)
end

function phys_write_u16(memory:: PhysicalMemory, addr:: UInt64, data:: UInt16)
	@inbounds isIO = memory.iomap[(addr >>> PAGE_BITS) + 1]
	if !isIO
		unsafe_store!(convert(Ptr{UInt16}, memory.baseptr + addr), data, 1);
		return
	end
	io_w16(memory, addr, data)
end

# 8-bit
@noinline function io_w8(memory:: PhysicalMemory, addr:: UInt64, data:: UInt8)
	seq = (addr >>> PAGE_BITS) + 1
	memory.iomap_w8[seq](memory.iomap_dev[seq], addr, data)
end

function phys_write_u8(memory:: PhysicalMemory, addr:: UInt64, data:: UInt8)
	@inbounds isIO = memory.iomap[(addr >>> PAGE_BITS) + 1]
	if !isIO
		unsafe_store!(convert(Ptr{UInt8}, memory.baseptr + addr), data, 1);
		return
	end
	io_w8(memory, addr, data)
end

# Copy buffer into physical RAM
function buffer_to_phys_ram(addr:: UInt64, len:: UInt64, buf:: Ptr{UInt8})
	while len > 0
		@inbounds isIO = g_phys_mem.iomap[(addr >>> PAGE_BITS) + 1]
		if isIO
			io_w8(g_phys_mem, addr, unsafe_load(buf, 1))
			len -= 1
			buf += 1
			addr += 1
		else
			l = min(((addr + PAGE_SIZE) & ~PAGE_MASK) - addr, len)
			ccall(("memcpy", "libc"), Ptr{Void}, (Ptr{Void}, Ptr{Void}, Csize_t,), convert(Ptr{Void}, g_phys_mem.baseptr + addr), buf, l)
			len -= l
			buf += l
			addr += l
		end
	end
end


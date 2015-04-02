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

function phys_read_s64(memory:: PhysicalMemory, addr:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		return unsafe_load(convert(Ptr{Int64}, memory.baseptr + addr), 1)
	end
	return Int64(io_r64(memory, addr))
end

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

function phys_read_s32(memory:: PhysicalMemory, addr:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		return unsafe_load(convert(Ptr{Int32}, memory.baseptr + addr), 1)
	end
	return Int32(io_r32(memory, addr))
end

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

function phys_read_s16(memory:: PhysicalMemory, addr:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		return unsafe_load(convert(Ptr{Int16}, memory.baseptr + addr), 1);
	end
	return Int16(io_r16(memory, addr))
end

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

function phys_read_s8(memory:: PhysicalMemory, addr:: UInt64)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		return unsafe_load(convert(Ptr{Int8}, memory.baseptr + addr), 1);
	end
	return reinterpret(Int8, io_r8(memory, addr))
end

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

function phys_write_s64(memory:: PhysicalMemory, addr:: UInt64, data:: Int64)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		unsafe_store!(convert(Ptr{Int64}, memory.baseptr + addr), data, 1);
		return
	end
	io_w64(memory, addr, data)
end

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

function phys_write_s32(memory:: PhysicalMemory, addr:: UInt64, data:: Int32)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		unsafe_store!(convert(Ptr{Int32}, memory.baseptr + addr), data, 1);
		return
	end
	io_w32(memory, addr, data)
end

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

function phys_write_s16(memory:: PhysicalMemory, addr:: UInt64, data:: Int16)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		unsafe_store!(convert(Ptr{Int16}, memory.baseptr + addr), data, 1);
		return
	end
	io_w16(memory, addr, data)
end

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

function phys_write_s8(memory:: PhysicalMemory, addr:: UInt64, data:: Int8)
	@inbounds isIO = memory.iomap[(addr >>> 12) + 1]
	if !isIO
		unsafe_store!(convert(Ptr{Int8}, memory.baseptr + addr), data, 1);
		return
	end
	io_w8(memory, addr, data)
end

# For code_native
function dummy(mem:: PhysicalMemory)
	return UInt64(phys_read_u64(mem, UInt64(0x100))) + 20
end

# Unit testing
if (length(ARGS) > 0) && ARGS[1] == "test"
	mem = PhysicalMemory(UInt64(4096*1024))
	println("Testing $(@__FILE__())...")
	@code_native(phys_read_u8(mem, UInt64(0x12340)))
	@code_native(phys_read_s8(mem, UInt64(0x12340)))
	@code_native(phys_write_u64(mem, UInt64(0x12340), 0x12345678deadbeef))
	@code_native(dummy(mem))
	dummy(mem)
	# Test basic r/w
	println("Testing basic r/w functions ... ")
	# read_u8 == write_u8
	println("read_u8 == write_u8")
	for i = 0 : mem.size - 1
		phys_write_u8(mem, UInt64(i), UInt8(0xab))
	end
	for i = 0 : mem.size - 1
		if phys_read_u8(mem, UInt64(i)) != UInt8(0xab)
			error("phys_read_u8 != phys_write_u8")
		end
	end

	# read_s8 == write_s8
	println("read_s8 == write_s8")
	for i = 0 : mem.size - 1
		phys_write_s8(mem, UInt64(i), Int8(-1))
	end
	for i = 0 : mem.size - 1
		if phys_read_s8(mem, UInt64(i)) != -1
			error("phys_read_s8 != phys_write_s8")
		end
	end

	for offset = 0 : 1
		println("read_u16 == write_u16, offset = $offset")
		# read_u16 == write_u16
		for i = range(offset, 2, Int((mem.size >> 1)))
			phys_write_u16(mem, UInt64(i), UInt16(0xdead))
		end
		for i = range(offset, 2, Int((mem.size >> 1)))
			if phys_read_u16(mem, UInt64(i)) != UInt16(0xdead)
				error("phys_read_u16 != phys_write_u16 on offset $(offset)")
			end
		end

		println("read_s16 == write_s16, offset = $offset")
		# read_s16 == write_s16
		for i = range(offset, 2, Int((mem.size >> 1)))
			phys_write_s16(mem, UInt64(i), Int16(-16384))
		end
		for i = range(offset, 2, Int((mem.size >> 1)))
			if phys_read_s16(mem, UInt64(i)) != Int16(-16384)
				error("phys_read_s16 != phys_write_s16 on offset $(offset)")
			end
		end
	end

	for offset = 0 : 3
		println("read_u32 == write_u32, offset = $offset")
		# read_u32 == write_u32
		for i = range(offset, 4, ((mem.size >> 2)))
			phys_write_u32(mem, UInt64(i), UInt32(0xdeadbeef))
		end
		for i = range(offset, 4, ((mem.size >> 2)))
			if phys_read_u32(mem, UInt64(i)) != UInt32(0xdeadbeef)
				error("phys_read_u32 != phys_write_u32 on offset $(offset)")
			end
		end

		println("read_s32 == write_s32, offset = $offset")
		# read_s32 == write_s32
		for i = range(offset, 4, Int((mem.size >> 2)))
			phys_write_s32(mem, UInt64(i), -Int32(0x12345678))
		end
		for i = range(offset, 4, Int((mem.size >> 2)))
			if phys_read_s32(mem, UInt64(i)) != -Int32(0x12345678)
				error("phys_read_s32 != phys_write_s32 on offset $(offset)")
			end
		end
	end

	for offset = 0 : 7 
		println("read_u64 == write_u64, offset = $offset")
		# read_u64 == write_u64
		for i = range(offset, 8, ((mem.size >> 3)))
			phys_write_u64(mem, UInt64(i), UInt64(0x87654321deadbeef))
		end
		for i = range(offset, 8, ((mem.size >> 3)))
			if phys_read_u64(mem, UInt64(i)) != UInt64(0x87654321deadbeef)
				error("phys_read_u64 != phys_write_u64 on offset $(offset)")
			end
		end

		println("read_s64 == write_s64, offset = $offset")
		# read_s64 == write_s64
		for i = range(offset, 8, ((mem.size >> 3)))
			phys_write_s64(mem, UInt64(i), -Int64(0x12345678deadbeef))
		end
		for i = range(offset, 8, ((mem.size >> 3)))
			if phys_read_s64(mem, UInt64(i)) != -Int64(0x12345678deadbeef)
				error("phys_read_s64 != phys_write_s64 on offset $(offset)")
			end
		end
	end

	println("OK")

	# Test misaligned and mismatched r/w
	print("Testing mismatched r/w (assuming little endian) ... ")
	for i = 0 : mem.size - 1
		phys_write_u8(mem, UInt64(i), UInt8(i & 0xff))
	end

	if phys_read_u16(mem, UInt64(0)) != UInt16(0x100)
		error("phys_read_u16 on 0001 != 0x0100")
	end
	if phys_read_u16(mem, UInt64(1)) != UInt16(0x201)
		error("phys_read_u16 on 0102 != 0x0201")
	end
	if phys_read_s16(mem, UInt64(0xfd)) != Int16(-259)
		error("phys_read_s16 on fdfe != -259")
	end
	if phys_read_u32(mem, UInt64(3)) != UInt32(0x6050403)
		error("phys_read_u32 on 03040506 != 0x06050403")
	end
	if phys_read_s32(mem, UInt64(0x81)) != Int32(-2071756159)
		error("phys_read_s32 on 81828384 != -2071756159")
	end
	if phys_read_u64(mem, UInt64(0x7d)) != UInt64(0x84838281807f7e7d)
		error("phys_read_u64 on 7d7e7f8081828384 != 0x84838281807f7e7d")
	end
	if phys_read_s64(mem, UInt64(0x9b)) != Int64(-6727919760893436773)
		error("phys_read_s64 on 9b9c9d9e9fa0a1a2 != -6727919760893436773")
	end
	println("OK")

	# Test IO mapping
	function read8(dev:: TestDev, addr:: UInt64)
		return 0xab
	end

	function read16(dev:: TestDev, addr:: UInt64)
		return 0xabcd
	end

	function read32(dev:: TestDev, addr:: UInt64)
		return 0xabcdefab
	end

	function read64(dev:: TestDev, addr:: UInt64)
		if addr == UInt64(0xe300)
			return dev.state
		end
		return 0xabcdefabdeadbeef
	end

	function write8(dev:: TestDev, addr:: UInt64, data:: UInt8)
	end

	function write16(dev:: TestDev, addr:: UInt64, data:: UInt16)
	end

	function write32(dev:: TestDev, addr:: UInt64, data:: UInt32)
		if addr == UInt64(0xe320)
			dev.state += data
		end
	end

	function write64(dev:: TestDev, addr:: UInt64, data:: UInt64)
	end

	print("Testing I/O mappinp ... ")
	fill!(mem.array, 0)
	dev = TestDev(0, 0)
	register_phys_io_map(mem, UInt64(0xe000), UInt64(0x1000), dev, 
			read64, read32, read16, read8,
			write64, write32, write16, write8)

	if phys_read_u64(mem, UInt64(0xe000)) != 0xabcdefabdeadbeef
		error("IO r64 on 0xe000 should be 0xabcdefabdeadbeef")
	end
	if phys_read_u16(mem, UInt64(0xe000)) != 0xabcd
		error("IO r16 on 0xe000 should be 0xabcd")
	end
	if phys_read_u64(mem, UInt64(0xf000)) != UInt64(0)
		error("IO r64 on 0xf000 should be 0")
	end
	if phys_read_u8(mem, UInt64(0xefff)) != UInt8(0xab)
		error("IO r8 on 0xefff should be 0xab")
	end
	phys_write_u32(mem, UInt64(0xe320), UInt32(1))
	phys_write_u32(mem, UInt64(0xe320), UInt32(2))
	phys_write_u32(mem, UInt64(0xe320), UInt32(3))
	phys_write_u32(mem, UInt64(0xe320), UInt32(4))
	if phys_read_u64(mem, UInt64(0xe300)) != UInt64(10)
		error("IO r64 on 0xe320 should be 10 after w32 on 0x320 1,2,3,4")
	end
	println("OK")
end

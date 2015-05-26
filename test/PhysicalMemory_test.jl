include("../PhysicalMemory.jl")
include("../hw/IODev.jl")

type TestDev <: IODev
	mmiobase:: UInt64
	state:: Int
end

# For code_native
function dummy(mem:: PhysicalMemory)
	return UInt64(phys_read_u64(mem, UInt64(0x100))) + 20
end

# Unit testing
mem = PhysicalMemory(UInt64(4096*1024))
println("Testing $(@__FILE__())...")
@code_native(phys_read_u8(mem, UInt64(0x12340)))
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

#=
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
=#
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
#=
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
=#
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
#=
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
=#
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
if phys_read_u32(mem, UInt64(3)) != UInt32(0x6050403)
	error("phys_read_u32 on 03040506 != 0x06050403")
end
if phys_read_u64(mem, UInt64(0x7d)) != UInt64(0x84838281807f7e7d)
	error("phys_read_u64 on 7d7e7f8081828384 != 0x84838281807f7e7d")
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

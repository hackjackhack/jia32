include("IODev.jl")

type EPROM <: IODev
	base:: UInt64
	imgpath:: UTF8String 
	imgbuf:: Array{UInt8}

	function EPROM(path:: UTF8String)
		rom = new(0, path)
		f = open(path, "r")
		rom.imgbuf = readbytes(f)
		return rom
	end
end

function eprom_r8(rom:: EPROM, addr:: UInt64)
	return UInt8(rom.imgbuf[addr - rom.base + 1])
end

function eprom_r16(rom:: EPROM, addr:: UInt64)
	return UInt16(rom.imgbuf[addr - rom.base + 1]) + (UInt16(rom.imgbuf[addr - rom.base + 2]) << 8)
end

function eprom_r32(rom:: EPROM, addr:: UInt64)
	return UInt32(rom.imgbuf[addr - rom.base + 1]) + (UInt16(rom.imgbuf[addr - rom.base + 2]) << 8) +
		(UInt32(rom.imgbuf[addr - rom.base + 3]) << 16) + (UInt16(rom.imgbuf[addr - rom.base + 4]) << 24)
end

function eprom_r64(rom:: EPROM, addr:: UInt64)
	return UInt64(rom.imgbuf[addr - rom.base + 1]) + (UInt16(rom.imgbuf[addr - rom.base + 2]) << 8) +
		(UInt64(rom.imgbuf[addr - rom.base + 3]) << 16) + (UInt16(rom.imgbuf[addr - rom.base + 4]) << 24)
		(UInt64(rom.imgbuf[addr - rom.base + 5]) << 32) + (UInt16(rom.imgbuf[addr - rom.base + 6]) << 40)
		(UInt64(rom.imgbuf[addr - rom.base + 7]) << 48) + (UInt16(rom.imgbuf[addr - rom.base + 8]) << 56)
end

function eprom_w8(rom:: EPROM, addr:: UInt64, data:: UInt8)
	error("EPROM is readonly")
end

function eprom_w16(rom:: EPROM, addr:: UInt64, data:: UInt16)
	error("EPROM is readonly")
end

function eprom_w32(rom:: EPROM, addr:: UInt64, data:: UInt32)
	error("EPROM is readonly")
end

function eprom_w64(rom:: EPROM, addr:: UInt64, data:: UInt64)
	error("EPROM is readonly")
end



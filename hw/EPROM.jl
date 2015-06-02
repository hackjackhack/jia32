include("IODev.jl")

type EPROM <: IODev
	mmiobase:: UInt64
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
	return UInt8(rom.imgbuf[@ZB(addr - rom.mmiobase)])
end

function eprom_r16(rom:: EPROM, addr:: UInt64)
	return UInt16(rom.imgbuf[@ZB(addr - rom.mmiobase)]) + (UInt16(rom.imgbuf[@ZB(addr - rom.mmiobase + 1)]) << 8)
end

function eprom_r32(rom:: EPROM, addr:: UInt64)
	return UInt32(rom.imgbuf[@ZB(addr - rom.mmiobase)]) + (UInt16(rom.imgbuf[@ZB(addr - rom.mmiobase + 1)]) << 8) +
		(UInt32(rom.imgbuf[@ZB(addr - rom.mmiobase + 2)]) << 16) + (UInt16(rom.imgbuf[@ZB(addr - rom.mmiobase + 3)]) << 24)
end

function eprom_r64(rom:: EPROM, addr:: UInt64)
	return UInt64(rom.imgbuf[@ZB(addr - rom.mmiobase)]) + (UInt16(rom.imgbuf[@ZB(addr - rom.mmiobase + 1)]) << 8) +
		(UInt64(rom.imgbuf[@ZB(addr - rom.mmiobase + 2)]) << 16) + (UInt16(rom.imgbuf[@ZB(addr - rom.mmiobase + 3)]) << 24)
		(UInt64(rom.imgbuf[@ZB(addr - rom.mmiobase + 4)]) << 32) + (UInt16(rom.imgbuf[@ZB(addr - rom.mmiobase + 5)]) << 40)
		(UInt64(rom.imgbuf[@ZB(addr - rom.mmiobase + 6)]) << 48) + (UInt16(rom.imgbuf[@ZB(addr - rom.mmiobase + 7)]) << 56)
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



include("MMIO.jl")

type EPROM <: MMIO
	base:: Uint64
	imgpath:: UTF8String 
	imgbuf:: Array{Uint8}

	function EPROM(path:: UTF8String)
		rom = new(0, path)
		f = open(path, "r")
		rom.imgbuf = readbytes(f)
		return rom
	end
end

function eprom_r8(rom:: EPROM, addr:: Uint64)
	return Uint8(rom.imgbuf[addr - rom.base + 1])
end

function eprom_r16(rom:: EPROM, addr:: Uint64)
	return Uint16(rom.imgbuf[addr - rom.base + 1]) + (Uint16(rom.imgbuf[addr - rom.base + 2]) << 8)
end

function eprom_r32(rom:: EPROM, addr:: Uint64)
	return Uint32(rom.imgbuf[addr - rom.base + 1]) + (Uint16(rom.imgbuf[addr - rom.base + 2]) << 8) +
		(Uint32(rom.imgbuf[addr - rom.base + 3]) << 16) + (Uint16(rom.imgbuf[addr - rom.base + 4]) << 24)
end

function eprom_r64(rom:: EPROM, addr:: Uint64)
	return Uint64(rom.imgbuf[addr - rom.base + 1]) + (Uint16(rom.imgbuf[addr - rom.base + 2]) << 8) +
		(Uint64(rom.imgbuf[addr - rom.base + 3]) << 16) + (Uint16(rom.imgbuf[addr - rom.base + 4]) << 24)
		(Uint64(rom.imgbuf[addr - rom.base + 5]) << 32) + (Uint16(rom.imgbuf[addr - rom.base + 6]) << 40)
		(Uint64(rom.imgbuf[addr - rom.base + 7]) << 48) + (Uint16(rom.imgbuf[addr - rom.base + 8]) << 56)
end


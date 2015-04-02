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

if length(ARGS) > 0 && ARGS[1] == "test"
	rom = EPROM(UTF8String("images/bios.bin"))
	if eprom_r8(rom, Uint64(0)) != Uint8(0x31)
		error("first byte of bios.bin should be 0x31")
	end

	if eprom_r16(rom, Uint64(0xb3)) != Uint16(0x5bd8)
		error("r16 at bios.bin[0xb3] should be 0x5bd8")
	end
end

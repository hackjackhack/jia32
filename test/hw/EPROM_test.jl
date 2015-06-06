include("../../Common.jl")
include("../../hw/EPROM.jl")

rom = EPROM(UTF8String("images/bios.bin"))
if eprom_r8(rom, Uint64(0)) != Uint8(0x31)
	error("first byte of bios.bin should be 0x31")
end

if eprom_r16(rom, Uint64(0xb3)) != Uint16(0x5bd8)
	error("r16 at bios.bin[0xb3] should be 0x5bd8")
end

println("OK")

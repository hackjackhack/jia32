include("../Common.jl")
include("../CPU.jl")
include("../PhysicalMemory.jl")

# ------------------- Testing -----------------------------
function dummy(cpu:: CPU)
	@reg_r_named(cpu, RAX)
end

function dummy2(cpu:: CPU)
	@reg_r_named(cpu, BX)
end

function dummy3(cpu:: CPU, r:: Int)
	@reg_r(cpu, UInt64, r)
end

function dummy4(cpu:: CPU)
	@reg_w_named!(cpu, RAX, 0x1234567887654321)
end

function dummy5(cpu:: CPU)
	@reg_w_named!(cpu, EAX, 0x12345678)
end

function dummy6(cpu:: CPU, r:: Int, data:: UInt64)
	@reg_w!(cpu, UInt64, r, data)
end

function dummy7(cpu:: CPU)
	@reg_w_named!(cpu, RCX, @reg_r_named(cpu, RAX))
end

function dummy8(cpu:: CPU)
	@reg_w32!(cpu, RCX, @reg_r32(cpu, RDX))
end

function dummy9(cpu:: CPU)
	@reg_w64!(cpu, RCX, UInt64(@reg_r32(cpu, RDX)))
end

mem = PhysicalMemory(UInt64(4096*1024))
cpu = CPU(UInt64(4096*1024))
reset(cpu)

println(macroexpand(:@reg_w32!(cpu, RCX, @reg_r32(cpu, RAX))))
# Show generated code
i = 3
@code_native(dummy(cpu))
println()
@code_native(dummy2(cpu))
println()
@code_native(dummy3(cpu, i))
println()
@code_native(dummy4(cpu))
println()
@code_native(dummy5(cpu))
println()
@code_native(dummy6(cpu, i, 0x1234567887654321))
println()
@code_native(dummy7(cpu))
println()
@code_native(dummy8(cpu))
println()
@code_native(dummy9(cpu))
println()
@code_native(logical_to_physical(cpu, 0, UInt64(0x1234)))
println()
@code_native(ru64(cpu, mem, 0, UInt64(0x1234)))
println()
@code_native(ru64_fast(cpu, mem, 0, UInt64(0x1234)))
println()
@code_native(rs64(cpu, mem, 0, UInt64(0x1234)))
println()
@code_native(ru32(cpu, mem, 0, UInt64(0x1234)))
println()
@code_native(ru32_fast(cpu, mem, 0, UInt64(0x1234)))
println()
@code_native(rs32(cpu, mem, 0, UInt64(0x1234)))
println()

# Testing r/w
print("Testing r/w functions ... ")
@reg_w_named!(cpu, RAX, 0x1234567887654321)
if @reg_r_named(cpu, EAX) != UInt32(0x87654321)
	error("EAX should be 0x87654321 after RAX <- 0x1234567887654321")
end
if @reg_r_named(cpu, AX) != UInt16(0x4321)
	error("AX should be 0x4321 after RAX <- 0x1234567887654321")
end

@reg_w_named!(cpu, EAX, 0xDEADBEEF)
if @reg_r_named(cpu, RAX) != UInt64(0x12345678deadbeef)
	error("RAX should be 0x12345678deadbeef after EAX <- 0xDEADBEEF")
end

@reg_w_named!(cpu, RCX, @reg_r_named(cpu, RAX))
if @reg_r_named(cpu, RCX) != UInt64(0x12345678deadbeef)
	error("RCX should be 0x12345678deadbeef after RCX <- RAX")
end

@reg_w_named!(cpu, CL, 0xAA)
if @reg_r_named(cpu, CX) != UInt16(0xbeaa)
	error("CX should be 0xbeaa after CL <- 0xaa")
end

@reg_w64!(cpu, RDI, @reg_r64(cpu, RAX))
if @reg_r64(cpu, RDI) != @reg_r64(cpu, RAX)
	error("RDI should equal to RAX after RDI<-RAX")
end

# Testing RIP
@rip!(cpu, 0xffffffffffff0000)
if @rip(cpu) != 0xffffffffffff0000
	error("RIP should be 0xffffffffffff0000")
end
if @eip(cpu) != 0xffff0000
	error("EIP should be 0xffff0000")
end
@eip!(cpu, 0x13572468)
if @rip(cpu) != 0xffffffff13572468
	error("RIP should be 0xffffffff13572468")
end


ru64(cpu, mem, DS, UInt64(0xff0))
println("OK")

include("IODev.jl")
include("PIC_I8259.jl")

type MC146818 <: IODev
	portlist_r32:: Dict{UInt64, Function}
	portlist_r16:: Dict{UInt64, Function}
	portlist_r8::  Dict{UInt64, Function}
	portlist_w32:: Dict{UInt64, Function}
	portlist_w16:: Dict{UInt64, Function}
	portlist_w8::  Dict{UInt64, Function}
	internal_c_obj:: Ptr{Void}

	function MC146818(base:: UInt64, i8259:: I8259, year:: Int, month:: Int, day:: Int)
		mc146818 = new(
			Dict{UInt64, Function}(),
			Dict{UInt64, Function}(),
			Dict{UInt64, Function}(),
			Dict{UInt64, Function}(),
			Dict{UInt64, Function}(),
			Dict{UInt64, Function}())
		mc146818.internal_c_obj = ccall(("RTC_c_init", HW_LIB_PATH),
						Ptr{Void},
						(Int32, Int32, Int32, Int32,),
						base % UInt32, year, month, day)
		mc146818.portlist_w8[base] = mc146818_ioport_write
		mc146818.portlist_w8[base + 1] = mc146818_ioport_write
		mc146818.portlist_r8[base] = mc146818_ioport_read
		mc146818.portlist_r8[base + 1] = mc146818_ioport_read

		return mc146818
	end 
end

function mc146818_ioport_write(mc146818:: MC146818, addr:: UInt64, data:: UInt8)
	ccall(("cmos_ioport_write", HW_LIB_PATH),
		Void,
		(Ptr{Void}, UInt32, UInt32,),
		mc146818.internal_c_obj, addr, UInt32(data)
	)
end

function mc146818_ioport_read(mc146818:: MC146818, addr:: UInt64)
	return UInt8(ccall(("cmos_ioport_read", HW_LIB_PATH),
		UInt32,
		(Ptr{Void}, UInt32,),
		mc146818.internal_c_obj, addr) & 0xff)
end

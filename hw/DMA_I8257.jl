include("IODev.jl")

type I8257 <: IODev
	portbase:: UInt64
	portlist_r32:: Dict{UInt64, Function}
	portlist_r16:: Dict{UInt64, Function}
	portlist_r8::  Dict{UInt64, Function}
	portlist_w32:: Dict{UInt64, Function}
	portlist_w16:: Dict{UInt64, Function}
	portlist_w8::  Dict{UInt64, Function}
	
	function I8257(seq:: Int)
		i8257 = new(0,
			    Dict{UInt64, Function}(),
			    Dict{UInt64, Function}(),
			    Dict{UInt64, Function}(),
			    Dict{UInt64, Function}(),
			    Dict{UInt64, Function}(),
			    Dict{UInt64, Function}())
		if (seq == 0)
			i8257.portlist_w8[0xd] = i8257_w8
		end
		return i8257
	end
end

function i8257_r8(i8257:: I8257, addr:: UInt64)
	return UInt8(0)
end

function i8257_r16(i8257:: I8257, addr:: UInt64)
	return UInt16(0)
end

function i8257_r32(i8257:: I8257, addr:: UInt64)
	return UInt32(0)
end

function i8257_w8(i8257:: I8257, addr:: UInt64, data:: UInt8)
	println("i8257_w8 port: $addr, data: $data")
end

function i8257_w16(i8257:: I8257, addr:: UInt64, data:: UInt16)
end

function i8257_w32(i8257:: I8257, addr:: UInt64, data:: UInt32)
end


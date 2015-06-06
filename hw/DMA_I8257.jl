include("IODev.jl")

type I8257 <: IODev
	portlist_r32:: Dict{UInt64, Function}
	portlist_r16:: Dict{UInt64, Function}
	portlist_r8::  Dict{UInt64, Function}
	portlist_w32:: Dict{UInt64, Function}
	portlist_w16:: Dict{UInt64, Function}
	portlist_w8::  Dict{UInt64, Function}
	internal_c_obj:: Ptr{Void}
	
	function I8257(base:: UInt64, dshift:: Int, page_base:: UInt64, pageh_base:: Int64)
		i8257 = new(Dict{UInt64, Function}(),
			    Dict{UInt64, Function}(),
			    Dict{UInt64, Function}(),
			    Dict{UInt64, Function}(),
			    Dict{UInt64, Function}(),
			    Dict{UInt64, Function}())
		i8257.internal_c_obj = ccall(("DMA_c_init", HW_LIB_PATH), Ptr{Void}, (Int32,), dshift)
		println(i8257.internal_c_obj)
		
		for i = 0 : 7
			i8257.portlist_w8[base + (i << dshift)] = i8257_write_chan
			i8257.portlist_r8[base + (i << dshift)] = i8257_read_chan
			i8257.portlist_w8[base + ((i + 8) << dshift)] = i8257_write_cont
			i8257.portlist_r8[base + ((i + 8) << dshift)] = i8257_read_cont
		end
		for p in [0x1, 0x2, 0x3, 0x7]
			i8257.portlist_w8[page_base + p] = i8257_write_page
			i8257.portlist_r8[page_base + p] = i8257_read_page
			if pageh_base >= 0
				i8257.portlist_w8[pageh_base + p] = i8257_write_pageh
				i8257.portlist_r8[pageh_base + p] = i8257_read_page
			end
		end
		
		return i8257
	end
end

function i8257_write_chan(i8257:: I8257, addr:: UInt64, data:: UInt8)
	ccall(("write_chan", HW_LIB_PATH),
		Void,
		(Ptr{Void}, UInt32, UInt32,),
		i8257.internal_c_obj, addr, UInt32(data))
end

function i8257_write_cont(i8257:: I8257, addr:: UInt64, data:: UInt8)
	ccall(("write_cont", HW_LIB_PATH),
		Void,
		(Ptr{Void}, UInt32, UInt32,),
		i8257.internal_c_obj, addr, UInt32(data))
end

function i8257_write_page(i8257:: I8257, addr:: UInt64, data:: UInt8)
	ccall(("write_page", HW_LIB_PATH),
		Void,
		(Ptr{Void}, UInt32, UInt32,),
		i8257.internal_c_obj, addr, UInt32(data))
end

function i8257_write_pageh(i8257:: I8257, addr:: UInt64, data:: UInt8)
	ccall(("write_pageh", HW_LIB_PATH),
		Void,
		(Ptr{Void}, UInt32, UInt32,),
		i8257.internal_c_obj, addr, UInt32(data))
end

function i8257_read_chan(i8257:: I8257, addr:: UInt64)
	return UInt8(ccall(("read_chan", HW_LIB_PATH),
		UInt32,
		(Ptr{Void}, UInt32,),
		i8257.internal_c_obj, addr) & 0xff)
end

function i8257_read_cont(i8257:: I8257, addr:: UInt64)
	return UInt8(ccall(("read_cont", HW_LIB_PATH),
		UInt32,
		(Ptr{Void}, UInt32,),
		i8257.internal_c_obj, addr) & 0xff)
end

function i8257_read_page(i8257:: I8257, addr:: UInt64)
	return UInt8(ccall(("read_page", HW_LIB_PATH),
		UInt32,
		(Ptr{Void}, UInt32,),
		i8257.internal_c_obj, addr) & 0xff)
end

function i8257_read_pageh(i8257:: I8257, addr:: UInt64)
	return UInt8(ccall(("read_pageh", HW_LIB_PATH),
		UInt32,
		(Ptr{Void}, UInt32,),
		i8257.internal_c_obj, addr) & 0xff)
end

include("IODev.jl")

type I8259 <: IODev
	portlist_r32:: Dict{UInt64, Function}
	portlist_r16:: Dict{UInt64, Function}
	portlist_r8::  Dict{UInt64, Function}
	portlist_w32:: Dict{UInt64, Function}
	portlist_w16:: Dict{UInt64, Function}
	portlist_w8::  Dict{UInt64, Function}
	internal_c_obj:: Ptr{Void}
	internal_c_obj_pic0:: Ptr{Void}
	internal_c_obj_pic1:: Ptr{Void}
	

	function I8259()
		i8259 = new(Dict{UInt64, Function}(),
			    Dict{UInt64, Function}(),
			    Dict{UInt64, Function}(),
			    Dict{UInt64, Function}(),
			    Dict{UInt64, Function}(),
			    Dict{UInt64, Function}())
		ppic0 = Ref{Ptr{Void}}(0)
		ppic1 = Ref{Ptr{Void}}(0)
		
		i8259.internal_c_obj = ccall(("I8259_c_init", HW_LIB_PATH), 
					Ptr{Void},
					(Ref{Ptr{Void}}, Ref{Ptr{Void}},),
					ppic0, ppic1
					)
		println("ppic0: $(ppic0[])")
		println("ppic1: $(ppic1[])")
		i8259.internal_c_obj_pic0 = ppic0[]
		i8259.internal_c_obj_pic1 = ppic1[]
	
		i8259.portlist_w8[0x20] = i8259_pic0_ioport_write
		i8259.portlist_r8[0x20] = i8259_pic0_ioport_read
		i8259.portlist_w8[0x21] = i8259_pic0_ioport_write
		i8259.portlist_r8[0x21] = i8259_pic0_ioport_read
		i8259.portlist_w8[0x4d0] = i8259_elcr0_ioport_write
		i8259.portlist_r8[0x4d0] = i8259_elcr0_ioport_read

		i8259.portlist_w8[0xa0] = i8259_pic1_ioport_write
		i8259.portlist_r8[0xa0] = i8259_pic1_ioport_read
		i8259.portlist_w8[0xa1] = i8259_pic1_ioport_write
		i8259.portlist_r8[0xa1] = i8259_pic1_ioport_read
		i8259.portlist_w8[0x4d1] = i8259_elcr1_ioport_write
		i8259.portlist_r8[0x4d1] = i8259_elcr1_ioport_read
		return i8259
	end
end

function i8259_pic0_ioport_write(i8259:: I8259, addr:: UInt64, data:: UInt8)
	ccall(("pic_ioport_write", HW_LIB_PATH),
		Void,
		(Ptr{Void}, UInt32, UInt32,),
		i8259.internal_c_obj_pic0, addr, UInt32(data))
end

function i8259_pic0_ioport_read(i8259:: I8259, addr:: UInt64)
	ccall(("pic_ioport_read", HW_LIB_PATH),
		UInt32,
		(Ptr{Void}, UInt32,),
		i8259.internal_c_obj_pic0, addr)
end

function i8259_elcr0_ioport_write(i8259:: I8259, addr:: UInt64, data:: UInt8)
	ccall(("elcr_ioport_write", HW_LIB_PATH),
		Void,
		(Ptr{Void}, UInt32, UInt32,),
		i8259.internal_c_obj_pic0, addr, data)
end

function i8259_elcr0_ioport_read(i8259:: I8259, addr:: UInt64)
	ccall(("elcr_ioport_read", HW_LIB_PATH),
		UInt32,
		(Ptr{Void}, UInt32,),
		i8259.internal_c_obj_pic0, addr)
end

function i8259_pic1_ioport_write(i8259:: I8259, addr:: UInt64, data:: UInt8)
	ccall(("pic_ioport_write", HW_LIB_PATH),
		Void,
		(Ptr{Void}, UInt32, UInt32,),
		i8259.internal_c_obj_pic1, addr, UInt32(data))
end

function i8259_pic1_ioport_read(i8259:: I8259, addr:: UInt64)
	ccall(("pic_ioport_read", HW_LIB_PATH),
		UInt32,
		(Ptr{Void}, UInt32,),
		i8259.internal_c_obj_pic1, addr)
end

function i8259_elcr1_ioport_write(i8259:: I8259, addr:: UInt64, data:: UInt8)
	ccall(("elcr_ioport_write", HW_LIB_PATH),
		Void,
		(Ptr{Void}, UInt32, UInt32,),
		i8259.internal_c_obj_pic1, addr, data)
end

function i8259_elcr1_ioport_read(i8259:: I8259, addr:: UInt64)
	ccall(("elcr_ioport_read", HW_LIB_PATH),
		UInt32,
		(Ptr{Void}, UInt32,),
		i8259.internal_c_obj_pic1, addr)
end

function connect_dev_to_irq(i8259:: I8259, dev:: IODev, nb_irq:: Int)
	ccall(("connect_dev_to_pic", HW_LIB_PATH),
		Void,
		(Ptr{Void}, Ptr{Void}, Int32,),
		i8259.internal_c_obj, dev.internal_c_obj, nb_irq)
end

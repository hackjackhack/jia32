module JIA32
	type PhysicalMemory
		size:: Uint64
		array:: Array{Uint8}
		baseptr:: Ptr{Uint8}

		function PhysicalMemory(size:: Uint64)
			# Extra space for buggy manipulation on the last word
			# (This should never happen since MMU will performance 
			# boundary check before accessing physical memory.) 
			m = new(size, Array(Uint8, size + 4096), 0)
			fill!(m.array, 0)
			m.baseptr = convert(Ptr{Uint8}, m.array)
			return m
		end
	end

	# Read access functions
	function phys_read_u64(memory:: PhysicalMemory, addr:: Uint64)
		return unsafe_load(convert(Ptr{Uint64}, memory.baseptr + addr), 1);
	end

	function phys_read_s64(memory:: PhysicalMemory, addr:: Uint64)
		return unsafe_load(convert(Ptr{Int64}, memory.baseptr + addr), 1);
	end

	function phys_read_u32(memory:: PhysicalMemory, addr:: Uint64)
		return unsafe_load(convert(Ptr{Uint32}, memory.baseptr + addr), 1);
	end

	function phys_read_s32(memory:: PhysicalMemory, addr:: Uint64)
		return unsafe_load(convert(Ptr{Int32}, memory.baseptr + addr), 1);
	end

	function phys_read_u16(memory:: PhysicalMemory, addr:: Uint64)
		return unsafe_load(convert(Ptr{Uint16}, memory.baseptr + addr), 1);
	end

	function phys_read_s16(memory:: PhysicalMemory, addr:: Uint64)
		return unsafe_load(convert(Ptr{Int16}, memory.baseptr + addr), 1);
	end

	function phys_read_u8(memory:: PhysicalMemory, addr:: Uint64)
		return unsafe_load(convert(Ptr{Uint8}, memory.baseptr + addr), 1);
	end

	function phys_read_s8(memory:: PhysicalMemory, addr:: Uint64)
		return unsafe_load(convert(Ptr{Int8}, memory.baseptr + addr), 1);
	end

	# Write access functions
	function phys_write_u64(memory:: PhysicalMemory, addr:: Uint64, data:: Uint64)
		return unsafe_store!(convert(Ptr{Uint64}, memory.baseptr + addr), data, 1);
	end

	function phys_write_s64(memory:: PhysicalMemory, addr:: Uint64, data:: Int64)
		return unsafe_store!(convert(Ptr{Int64}, memory.baseptr + addr), data, 1);
	end

	function phys_write_u32(memory:: PhysicalMemory, addr:: Uint64, data:: Uint32)
		return unsafe_store!(convert(Ptr{Uint32}, memory.baseptr + addr), data, 1);
	end

	function phys_write_s32(memory:: PhysicalMemory, addr:: Uint64, data:: Int32)
		return unsafe_store!(convert(Ptr{Int32}, memory.baseptr + addr), data, 1);
	end

	function phys_write_u16(memory:: PhysicalMemory, addr:: Uint64, data:: Uint16)
		return unsafe_store!(convert(Ptr{Uint16}, memory.baseptr + addr), data, 1);
	end

	function phys_write_s16(memory:: PhysicalMemory, addr:: Uint64, data:: Int16)
		return unsafe_store!(convert(Ptr{Int16}, memory.baseptr + addr), data, 1);
	end

	function phys_write_u8(memory:: PhysicalMemory, addr:: Uint64, data:: Uint8)
		return unsafe_store!(convert(Ptr{Uint8}, memory.baseptr + addr), data, 1);
	end

	function phys_write_s8(memory:: PhysicalMemory, addr:: Uint64, data:: Int8)
		return unsafe_store!(convert(Ptr{Int8}, memory.baseptr + addr), data, 1);
	end

	# For code_native
	function dummy(mem:: PhysicalMemory)
		for i = 0 : mem.size - 1
			JIA32.phys_write_u8(mem, uint64(i), uint8(i & 0xff))
		end
	end

	# Unit testing
	if (length(ARGS) > 0) && ARGS[1] == "test"
		mem = JIA32.PhysicalMemory(uint64(4096*1024))

		println("Testing $(@__FILE__())...")

		# Test basic r/w
		print("Testing basic r/w functions ... ")
		# read_u8 == write_u8
		for i = 0 : mem.size - 1
			JIA32.phys_write_u8(mem, uint64(i), uint8(0xab))
		end
		for i = 0 : mem.size - 1
			if JIA32.phys_read_u8(mem, uint64(i)) != uint8(0xab)
				error("phys_read_u8 != phys_write_u8")
			end
		end

		# read_s8 == write_s8
		for i = 0 : mem.size - 1
			JIA32.phys_write_s8(mem, uint64(i), int8(-1))
		end
		for i = 0 : mem.size - 1
			if JIA32.phys_read_s8(mem, uint64(i)) != -1
				error("phys_read_s8 != phys_write_s8")
			end
		end

		for offset = 0 : 1
			# read_u16 == write_u16
			for i = range(offset, 2, int((mem.size >> 1)))
				JIA32.phys_write_u16(mem, uint64(i), uint16(0xdead))
			end
			for i = range(offset, 2, int((mem.size >> 1)))
				if JIA32.phys_read_u16(mem, uint64(i)) != uint16(0xdead)
					error("phys_read_u16 != phys_write_u16 on offset $(offset)")
				end
			end

			# read_s16 == write_s16
			for i = range(offset, 2, int((mem.size >> 1)))
				JIA32.phys_write_s16(mem, uint64(i), int16(-16384))
			end
			for i = range(offset, 2, int((mem.size >> 1)))
				if JIA32.phys_read_s16(mem, uint64(i)) != int16(-16384)
					error("phys_read_s16 != phys_write_s16 on offset $(offset)")
				end
			end
		end

		for offset = 0 : 3
			# read_u32 == write_u32
			for i = range(offset, 4, int((mem.size >> 2)))
				JIA32.phys_write_u32(mem, uint64(i), uint32(0xdeadbeef))
			end
			for i = range(offset, 4, int((mem.size >> 2)))
				if JIA32.phys_read_u32(mem, uint64(i)) != uint32(0xdeadbeef)
					error("phys_read_u32 != phys_write_u32 on offset $(offset)")
				end
			end

			# read_s32 == write_s32
			for i = range(offset, 4, int((mem.size >> 2)))
				JIA32.phys_write_s32(mem, uint64(i), int32(-0x12345678))
			end
			for i = range(offset, 4, int((mem.size >> 2)))
				if JIA32.phys_read_s32(mem, uint64(i)) != int32(-0x12345678)
					error("phys_read_s32 != phys_write_s32 on offset $(offset)")
				end
			end
		end

		for offset = 0 : 7 
			# read_u64 == write_u64
			for i = range(offset, 8, int((mem.size >> 3)))
				JIA32.phys_write_u64(mem, uint64(i), uint64(0x87654321deadbeef))
			end
			for i = range(offset, 8, int((mem.size >> 3)))
				if JIA32.phys_read_u64(mem, uint64(i)) != uint64(0x87654321deadbeef)
					error("phys_read_u64 != phys_write_u64 on offset $(offset)")
				end
			end

			# read_s64 == write_s64
			for i = range(offset, 8, int((mem.size >> 3)))
				JIA32.phys_write_s64(mem, uint64(i), int64(-0x12345678deadbeef))
			end
			for i = range(offset, 8, int((mem.size >> 3)))
				if JIA32.phys_read_s64(mem, uint64(i)) != int64(-0x12345678deadbeef)
					error("phys_read_s64 != phys_write_s64 on offset $(offset)")
				end
			end
		end

		# Test misaligned and mismatched r/w
		println("OK")
		print("Testing mismatched r/w (assuming little endian) ... ")
		for i = 0 : mem.size - 1
			JIA32.phys_write_u8(mem, uint64(i), uint8(i & 0xff))
		end

		if JIA32.phys_read_u16(mem, uint64(0)) != uint16(0x100)
			error("phys_read_u16 on 0001 != 0x0100")
		end
		if JIA32.phys_read_u16(mem, uint64(1)) != uint16(0x201)
			error("phys_read_u16 on 0102 != 0x0201")
		end
		if JIA32.phys_read_s16(mem, uint64(0xfd)) != int16(-259)
			error("phys_read_s16 on fdfe != -259")
		end
		if JIA32.phys_read_u32(mem, uint64(3)) != uint32(0x6050403)
			error("phys_read_u32 on 03040506 != 0x06050403")
		end
		if JIA32.phys_read_s32(mem, uint64(0x81)) != int32(-2071756159)
			error("phys_read_s32 on 81828384 != -2071756159")
		end
		if JIA32.phys_read_u64(mem, uint64(0x7d)) != uint64(0x84838281807f7e7d)
			error("phys_read_u64 on 7d7e7f8081828384 != 0x84838281807f7e7d")
		end
		if JIA32.phys_read_s64(mem, uint64(0x9b)) != int64(-6727919760893436773)
			error("phys_read_s64 on 9b9c9d9e9fa0a1a2 != -6727919760893436773")
		end
		println("OK")

		#@code_native(JIA32.dummy(mem))
	end
end

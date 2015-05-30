const NANOSEC_PER_INSTR = 1

type CTimer
	callback:: Ptr{Void} 
	object:: Ptr{Void}
	expire_time:: UInt64

	function CTimer(cb:: Ptr{Void}, obj:: Ptr{Void})
		return new(cb, obj, typemax(UInt64))
	end
end

type InstructionClock
	time:: UInt64
	next_expire_time:: UInt64
	timers:: Array{CTimer}
	
	function InstructionClock()
		clock = new(0, typemax(UInt64))
		clock.timers = Array(CTimer, 0)
		return clock
	end
end

function update_clock(clock:: InstructionClock, nb_instr:: UInt64)
	# Update clock
	clock.time += nb_instr * NANOSEC_PER_INSTR

	# 1. Fire all expired timers
	# 2. Find the next expiring time in the timers left
	if (clock.time >= clock.next_expire_time)
		clock.next_expire_time = typemax(UInt64)
		for t in clock.timers
			if clock.time >= t.expire_time
				t.callback(t.object)
			else
				if t.expire_time < clock.next_expire_time
					clock.next_expire_time = t.expire_time
				end
			end
		end
	end
end

function get_clock()
	return UInt64(g_clock.time)
end

function new_timer(callback:: Ptr{Void}, object:: Ptr{Void})
	push!(g_clock.timers, CTimer(callback, object))
	return Int64(length(g_clock.timers))
end

function mod_timer(key:: Int64, time_to_expire:: UInt64)
	g_clock.timers[key].expire_time = time_to_expire
	return
end

function cancel_timer(key:: Int64)
	g_clock.timers[key].expire_time = typemax(UInt64)
	return
end

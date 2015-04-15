all:
	./julia gen_instr.jl

clean:
	rm instr/*.jl

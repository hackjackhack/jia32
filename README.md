# jia32
Julia-based IA32 emulator 

Hopefully, this will fly.

Compilation:
Although Julia does not require compilation, JIA32 uses its own templating system to generate instruction emulation/JIT code. Please execute 'make' before first time execution.

Usage:
./julia main.jl

Test:
./julia test/???_test.jl

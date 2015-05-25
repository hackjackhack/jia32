#include "qemu_common.h"
#include "interface.h"

// Collector for the return state of C part
struct c_ret_collector_t c_ret_state;

// Pointer to the physical memory of the VM
uint8_t *phys_ram_base;

// Pointers to direct physical memory access function in Julia
void (*j_phys_ram_to_buffer)(uint64_t addr, uint64_t len, uint8_t* buf);
void (*j_buffer_to_phys_ram)(uint64_t addr, uint64_t len, const uint8_t* buf);

void init_c_world(uint8_t* baseptr, 
			void (*cb_phys_ram_to_buffer)(uint64_t, uint64_t, uint8_t*),
			void (*cb_buffer_to_phys_ram)(uint64_t, uint64_t, const uint8_t*))
{
	phys_ram_base = baseptr;
	j_phys_ram_to_buffer = cb_phys_ram_to_buffer;
	j_buffer_to_phys_ram = cb_buffer_to_phys_ram;

	fprintf(stderr, "phys_ram_base = %p\n", phys_ram_base);
}

void cpu_physical_memory_read(target_phys_addr_t addr,
                                            uint8_t *buf, int len)
{
	j_phys_ram_to_buffer(addr, len, buf);
}

void cpu_physical_memory_write(target_phys_addr_t addr,
                                             const uint8_t *buf, int len)
{
	j_buffer_to_phys_ram(addr, len, buf);
}

int phys_ram_c_access_test()
{
	uint8_t buf[5162];
	uint8_t buf2[6000];
	int i;

	for (i = 0 ; i < 5162 ; i++)
		buf[i] = i & 0xff;

	cpu_physical_memory_write(0x1234, buf, 5162);
	cpu_physical_memory_read(0x1234, buf2, 5162);

	for (i = 0 ; i < 5162 ; i++)
	{
		if (buf[i] != buf2[i])
			return -1;	
	}

	cpu_physical_memory_write(0x10000 , buf, 5162);
	cpu_physical_memory_read(0x10000, buf2, 5162);

	for (i = 0 ; i < 5162 ; i++)
	{
		if (buf[i] != buf2[i])
			return -1;	
	}

	cpu_physical_memory_write(0x2000 , buf, 1024);
	cpu_physical_memory_read(0x2000, buf2, 1024);

	for (i = 0 ; i < 1024 ; i++)
	{
		if (buf[i] != buf2[i])
			return -1;	
	}

	cpu_physical_memory_write(0x2000 , buf, 4096);
	cpu_physical_memory_read(0x2000, buf2, 4096);

	for (i = 0 ; i < 1024 ; i++)
	{
		if (buf[i] != buf2[i])
			return -1;	
	}

	cpu_physical_memory_write(0x3100 , buf, 798);
	cpu_physical_memory_read(0x3100, buf2, 798);

	for (i = 0 ; i < 798 ; i++)
	{
		if (buf[i] != buf2[i])
			return -1;	
	}

	return 0;
}

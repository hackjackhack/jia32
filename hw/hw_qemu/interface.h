#ifndef __INTERFACE_H__
#define __INTERFACE_H__

#include <stdint.h>
#include "qemu_common.h"

struct c_ret_collector_t {
    uint64_t interrupt_request;
};

extern struct c_ret_collector_t c_ret_state;

void cpu_physical_memory_read(target_phys_addr_t addr, uint8_t *buf, int len);

void cpu_physical_memory_write(target_phys_addr_t addr, const uint8_t *buf, int len);
#endif

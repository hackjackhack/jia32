#ifndef __INTERFACE_H__
#define __INTERFACE_H__

#include <stdint.h>
#include "qemu_common.h"

struct c_ret_collector_t {
    uint64_t interrupt_request;
};

extern struct c_ret_collector_t c_ret_state;

extern void (*j_cpu_interrupt)(void* opaque, int irq, int level);
extern int64_t (*j_new_timer)(void *cb, void *obj);
extern void (*j_mod_timer)(int64_t key, uint64_t time_to_expire);
extern void (*j_cancel_timer)(int64_t key);
extern uint64_t (*j_get_clock)();

void cpu_physical_memory_read(target_phys_addr_t addr, uint8_t *buf, int len);

void cpu_physical_memory_write(target_phys_addr_t addr, const uint8_t *buf, int len);
#endif

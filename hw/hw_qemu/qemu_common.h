#ifndef __QEMU_COMMON_H__
#define __QEMU_COMMON_H__

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define QEMU_TIMER_BASE 1000000000LL

// Memory management functions
void qemu_free(void *ptr);
void *qemu_malloc(size_t size);
void *qemu_realloc(void *ptr, size_t size);
void *qemu_mallocz(size_t size);

#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))
#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#define MAX(a, b) (((a) > (b)) ? (a) : (b))

#define CPU_INTERRUPT_EXIT   0x01 /* wants exit from main loop */
#define CPU_INTERRUPT_HARD   0x02 /* hardware interrupt pending */
#define CPU_INTERRUPT_EXITTB 0x04 /* exit the current TB (use for x86 a20 case) */
#define CPU_INTERRUPT_TIMER  0x08 /* internal timer exception pending */
#define CPU_INTERRUPT_FIQ    0x10 /* Fast interrupt pending.  */
#define CPU_INTERRUPT_HALT   0x20 /* CPU halt wanted */
#define CPU_INTERRUPT_SMI    0x40 /* (x86 only) SMI interrupt pending */
#define CPU_INTERRUPT_DEBUG  0x80 /* Debug event occured.  */
#define CPU_INTERRUPT_VIRQ   0x100 /* virtual interrupt pending.  */
#define CPU_INTERRUPT_NMI    0x200 /* NMI pending. */


typedef uint64_t target_phys_addr_t ;

typedef int (*DMA_transfer_handler) (void *opaque, int nchan, int pos, int size);

/***********************************************************/
/* bottom halves (can be seen as timers which expire ASAP) */
typedef void QEMUBHFunc(void *opaque);

struct QEMUBH {
    QEMUBHFunc *cb;
    void *opaque;
    int scheduled;
    int idle;
    int deleted;
    struct QEMUBH *next;
};

typedef struct QEMUBH QEMUBH;

QEMUBH *qemu_bh_new(QEMUBHFunc *cb, void *opaque);
int qemu_bh_poll(void);
void qemu_bh_schedule_idle(QEMUBH *bh);
void qemu_bh_schedule(QEMUBH *bh);
void qemu_bh_cancel(QEMUBH *bh);
void qemu_bh_delete(QEMUBH *bh);
void qemu_bh_update_timeout(int *timeout);

uint64_t muldiv64(uint64_t a, uint32_t b, uint32_t c);
#endif

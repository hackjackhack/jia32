#ifndef __PIC_I8259_H__
#define __PIC_I8259_H__

#include "irq.h"

typedef struct PicState2 PicState2;

typedef struct PicState {
    uint8_t last_irr; /* edge detection */
    uint8_t irr; /* interrupt request register */
    uint8_t imr; /* interrupt mask register */
    uint8_t isr; /* interrupt service register */
    uint8_t priority_add; /* highest irq priority */
    uint8_t irq_base;
    uint8_t read_reg_select;
    uint8_t poll;
    uint8_t special_mask;
    uint8_t init_state;
    uint8_t auto_eoi;
    uint8_t rotate_on_auto_eoi;
    uint8_t special_fully_nested_mode;
    uint8_t init4; /* true if 4 byte init */
    uint8_t single_mode; /* true if slave pic is not initialized */
    uint8_t elcr; /* PIIX edge/trigger selection*/
    uint8_t elcr_mask;
    PicState2 *pics_state;
} PicState;

struct PicState2 {
    /* 0 is master pic, 1 is slave pic */
    /* XXX: better separation between the two pics */
    PicState pics[2];
    qemu_irq parent_irq;
    void *irq_request_opaque;
    /* IOAPIC callback support */
    SetIRQFunc *alt_irq_func;
    void *alt_irq_opaque;
    qemu_irq* children_irqs;
};


#endif

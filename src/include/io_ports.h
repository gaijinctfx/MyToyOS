#ifndef __io_ports_h__
#define __io_ports_h__

/*---------------------------------------
    DMAC
  ---------------------------------------*/
#define DMAC0_BASE  0x0000

/* 16 bits registers */
#define DMAC0_CH0_ADDR      (DMAC0_BASE+0)
#define DMAC0_CH0_WORDCOUNT (DMAC0_BASE+1)
#define DMAC0_CH1_ADDR      (DMAC0_BASE+2)
#define DMAC0_CH1_WORDCOUNT (DMAC0_BASE+3)
#define DMAC0_CH2_ADDR      (DMAC0_BASE+4)
#define DMAC0_CH2_WORDCOUNT (DMAC0_BASE+5)
#define DMAC0_CH3_ADDR      (DMAC0_BASE+6)
#define DMAC0_CH3_WORDCOUNT (DMAC0_BASE+7)

#define DMAC0_STATUS        (DMAC0_BASE+8)  /* Read */
#define DMAC0_CMD           (DMAC0_BASE+8)  /* Write */
#define DMAC0_WRITE_REQ     (DMAC0_BASE+9)  /* Write */
#define DMAC0_MASK          (DMAC0_BASE+10)
#define DMAC0_MODE          (DMAC0_BASE+11) /* Write */
#define DMAC0_CLEAR_FF      (DMAC0_BASE+12) /* Write */
#define DMAC0_TEMP          (DMAC0_BASE+13) /* Read */
#define DMAC0_MASTER_CLEAR  (DMAC0_BASE+13) /* Write */
#define DMAC0_CLEAR_MASK    (DMAC0_BASE+14) /* Write */
#define DMAC0_WRITE_MASK    (DMAC0_BASE+15)

/* BitMasks */

#define DMAC_CH_REQ(ch)       (1 << (((ch) & 3)+4))
#define DMAC_CH_TERMCOUNT(ch) (1 << ((ch) & 3))

#define DMAC_CMD_DACK_HIGH    0x80
#define DMAC_CMD_DREQ_HIGH    0x40
#define DMAC_CMD_EXT_WRITE    0x20
#define DMAC_CMD_ROT_PRI      0x10
#define DMAC_CMD_COMPRTIMING  0x08
#define DMAC_CMD_ENABLE       0x04

#define DMAC_MASK_SET         0x04
#define DMAC_MASK_CH(ch)      ((ch) & 3)

#define DMAC_MODE_DEMAND      0x00
#define DMAC_MODE_SINGLE      0x40
#define DMAC_MODE_BLOCK       0x80
#define DMAC_MODE_CASCADE     0xc0
#define DMAC_MODE_ADDRINC     0x00
#define DMAC_MODE_ADDRDEC     0x20
#define DMAC_MODE_VERIFY      0x00
#define DMAC_MODE_WRITE       0x04
#define DMAC_MODE_READ        0x08
#define DMAC_MODE_RESERVED    0x0c  /* Memory 2 Memory? */
#define DMAC_MODE_CH(ch)      ((ch) & 3)

/*---------------------------------------
    PIC
  ---------------------------------------*/
#define PIC0_BASE              0x20

#define PIC0_ICW1              (PIC0_BASE+0)  /* Write */
#define PIC0_ICW2              (PIC0_BASE+1)  /* Write */
#define PIC0_ICW3              PIC0_ICW2      /* Write */
#define PIC0_ICW4              PIC0_ICW2      /* Write */
#define PIC0_OCW1              PIC0_ICW2
#define PIC0_OCW2              PIC0_OCW1
#define PIC0_OCW3              PIC0_OCW1
#define PIC0_IRR_ISR           PIC0_ICW1

/* Bitmasks */

#define PIC_ICW1_BIT           0x10
#define PIC_ICW1_EDGE          0x00
#define PIC_ICW1_LEVEL         0x08
#define PIC_ICW1_USE8          0x00
#define PIC_ICW1_USE4          0x04
#define PIC_ICW1_NEED_ICW4     0x01

#define PIC_ICW2_VECTOR(v)     (((v) & 0xf) << 4)

#define PIC_ICW3_SLAVE_IRQ(irq) ((irq) & 0xff)

/* Implied 8086 mode */
#define PIC_ICW4_SPECIAL_FULLY_NESTED_MODE  0x11
#define PIC_ICW4_UNBUFFERED_MODE            0x01
#define PIC_ICW4_BUFFERED_SLAVE             0x09
#define PIC_ICW4_BUFFERED_MASTER            0x0d
#define PIC_ICW4_AUTO_EOI                   0x03

#define PIC_OCW1_MASK(irqs)   ((irqs) & 0xff)

#define PIC_OCW2_ROTATE_AUTO_EOI_CLR      0x00
#define PIC_OCW2_NON_SPECIFIC_EOI         0x20    /* will be used all the time! */
#define PIC_OCW2_NOP                      0x40
#define PIC_OCW2_SPECIFIC_EOI             0x60
#define PIC_OCW2_ROTATE_AUTO_EOI_SET      0x80
#define PIC_OCW2_ROTATE_NON_SPECIFIC_EOI  0xa0
#define PIC_OCW2_SET_PRIORITY_CMD         0xc0
#define PIC_OCW2_ROTATE_SPECIFIC_EOI      0xe0
#define PIC_OCW2_IRQ(irq)                 ((irq) & 7)

#define PIC_OCW3_RESET_SPECIAL_MASK       0x40
#define PIC_OCW3_SET_SPECIAL_MASK         0x60
#define PIC_OCW3_POLL_CMD                 0x04
#define PIC_OCW3_READ_IRR                 0x02
#define PIC_OCW3_READ_ISR                 0x03

/*---------------------------------------
    PIT
  ---------------------------------------*/
#define PIT_BASE    0x0040
#define PIT_CH0_COUNTER   (PIT_BASE+0)
#define PIT_SPKR_COUNTER  (PIT_BASE+2)
#define PIT_MODE          (PIT_BASE+3)

/* Bitmaps */

#define PIT_MODE_COUNTER(ch) (((ch) & 3) << 6)
#define PIT_MODE_LATCH      0x00
#define PIT_MODE_RW_LSB     0x10
#define PIT_MODE_RW_MSB     0x20
#define PIT_MODE_RW_LSBMSB  0x30
#define PIT_MODE_MODE(m)    (((m) & 7) << 1)
#define PIT_MODE_ONESHOT    PIT_MODE_MODE(1)
#define PIT_MODE_RATEGEN    PIT_MODE_MODE(2)
#define PIT_MODE_SQRWAV     PIT_MODE_MODE(3)
#define PIT_MODE_SWSTROBE   PIT_MODE_MODE(4)
#define PIT_MODE_HWSTROBE   PIT_MODE_MODE(5)
#define PIT_MODE_BCD        0x01

/*---------------------------------------
    KBDC (AT)
  ---------------------------------------*/
#define KBDC_BASE       0x60
#define KBDC_CTRL_DATA  (KBDC_BASE+0)
#define KBDC_PORTB      (KBDC_BASE+1)
#define KBDC_STATUS     (KBDC_BASE+4)

/* Bitmasks */
#define KBDC_STATUS_PARITYERR 0x80
#define KBDC_STATUS_RECV_TOUT 0x40
#define KBDC_STATUS_TX_TOUT   0x20
#define KBDC_STATUS_KBINHIBIT 0x10
#define KBDC_STATUS_CMD       0x08    /* bit is zero if data. */
#define KBDC_STATUS_INBUFF_FULL 0x02
#define KBDC_STATUS_OUTBUFF_FULL 0x01

#define KBDC_PORTB_SPKR_ENABLE        0x02
#define KBDC_PORTB_SPKR_TIMER_ENABLE  0x01

#endif

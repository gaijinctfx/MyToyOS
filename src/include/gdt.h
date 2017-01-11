#ifndef __gdt_h__
#define __gdt_h__

#include <typedefs.h>

// Structure to load into GDTR.
struct gdt_descriptor_s {
  _u32 base;
  _u16 limit;
};
  
/*
      3                   2                   1
    1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
   +---------------+-+-+-+-+-------+-+---+-+-------+---------------+
   |               | |D| |A|  Seg  | | D | |       |               |
   |  Base[31:24]  |G|\|L|V| Limit |P| P |S|  Type |  Base[23:16]  |  +4
   |               | |B| |L|[19:16]| | L | |       |               |
   +---------------+-+-+-+-+-------+-+---+-+-------+---------------+

   +-------------------------------+-------------------------------+
   |                               |                               |
   |         Base[15:0]            |        Seg Limit[15:0]        |  +0
   |                               |                               |
   +-------------------------------+-------------------------------+
 */
struct gdt_s {
  _u64 limit_lo:16;
  _u64 base_lo:24;
  _u64 type:8;        // type (lsb), descriptor priviledge and flags (Present and System) (msb)
  _u64 limit_hi:4;
  _u64 flags:4;       // AVL, L (unused, must be 0), D/B (1 = 32 bits) and G (1 = 4 KiB granulity) flags.
  _u64 base_hi:8;
};

// Bitfields to use in type field.
#define GDT_SYSFLAG     0x10
#define GDT_PFLAG       0x80
#define GDT_DPL(p) (((p) & 0x03) << 1)
#define GDT_TYPE_XR   0x0a
#define GDT_TYPE_DRW  0x02

// Bitfields to use in flags field.
#define GDT_GFLAG   0x08
#define GDT_DBFLAG  0x04
#define GDT_AVLFLAG 0x01


#endif

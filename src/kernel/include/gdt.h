#ifndef __gdt_h__
#define __gdt_h__

#include <typedefs.h>

struct gdt_descriptor_s {
  _u32 base;
  _u16 limit;
};
  

struct gdt_s {
  _u64 limit_lo:16;
  _u64 base_lo:24;
  _u64 type:8;        // type (lsb) and priviledge (msb)
  _u64 limit_hi:4;
  _u64 flags:4;
  _u64 base_hi:8;
};

#endif

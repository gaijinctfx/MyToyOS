#ifndef __gdt_h__
#define __gdt_h__

#include <stdint.h>

struct gdt_descriptor_s {
  uint32_t base;
  uint16_t limit;
};
  

struct gdt_s {
  uint64_t limit_lo:16;
  uint64_t base_lo:24;
  uint64_t type:8;        // type (lsb) and priviledge (msb)
  uint64_t limit_hi:4;
  uint64_t flags:4;
  uint64_t base_hi:8;
};

#endif

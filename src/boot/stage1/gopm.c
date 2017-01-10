// 16 bits code
#include <stdint.h>
#include "gdt.h"

struct gdt_s gdt[3] = {
  { 0 },    // NULL descriptor
  { 0xffff, 0, 0x9a, 0xf, 0xc, 0 },    // code descriptor.
  { 0xffff, 0, 0x92, 0xf, 0xc, 0 }     // data descriptror.
};

struct gdt_descriptor_s gdt_desc;

void setup_pm(void)
{
  gdt_desc.limit = sizeof(gdt)-1;
  gdt_desc.base = (_u32)gdt;
}

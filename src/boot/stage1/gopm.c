// 16 bits code
#include <stdint.h>
#include "gdt.h"

struct gdt_s gdt[3] = {
  { 0 },    // NULL descriptor
  { 0xffff, 0, 0x9a, 0xf, 0xc, 0 },    // code descriptor.
  { 0xffff, 0, 0x92, 0xf, 0xc, 0 }     // data descriptror.
};

struct gdt_descriptor_s gdt_desc;

extern void _main32(void);

void __attribute__((noreturn)) go_pm(void)
{
  gdt_desc.base = (uint32_t)gdt;
  gdt_desc.limit = sizeof(gdt)-1;

  __asm__ __volatile__ ( "lgdt [gdt_desc]\n"
                         "jmp 8:_main32" );
}

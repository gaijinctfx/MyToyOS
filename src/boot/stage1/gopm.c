// 16 bits code
#include <typedefs.h>
#include <hw_io.h>
#include <a20.h>
#include <gdt.h>
#include <utils.h>

struct gdt_s gdt[3] = {
  { 0 },    // NULL descriptor
  { 0xffff, 0, 0x9a, 0xf, 0xc, 0 },    // code descriptor.
  { 0xffff, 0, 0x92, 0xf, 0xc, 0 }     // data descriptror.
};

struct gdt_descriptor_s gdt_desc;

// called by stage1.asm.
void setup_pm(void)
{
  if (!enable_a20())
  {
    real_puts("[!] ERROR enabling gate A20!");
    halt();
  }

  gdt_desc.limit = sizeof(gdt)-1;
  gdt_desc.base = (_u32)gdt;
}

// 16 bits code
#include <typedefs.h>
#include <hw_io.h>
#include <gdt.h>
#include <real/utils.h>
#include <real/a20.h>

struct gdt_s gdt[3] = {
  { 0 },    // NULL descriptor
  { 0xffff, 0, GDT_SYSFLAG | GDT_PFLAG | GDT_DPL(0) | GDT_TYPE_XR,  0xf, GDT_GFLAG | GDT_DBFLAG, 0 },    // code descriptor.
  { 0xffff, 0, GDT_SYSFLAG | GDT_PFLAG | GDT_DPL(0) | GDT_TYPE_DRW, 0xf, GDT_GFLAG | GDT_DBFLAG, 0 }     // data descriptror.
};

struct gdt_descriptor_s gdt_desc;

// called by stage1.asm.
int setup_pm(void)
{
  if (!enable_a20())
  {
    r_puts("[!] ERROR enabling gate A20!");
    return 1;
  }

  gdt_desc.limit = sizeof(gdt)-1;
  gdt_desc.base = (_u32)gdt;

  return 0;   // 0 means OK.
}

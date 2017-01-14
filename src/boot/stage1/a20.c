// 16 bits code.
#include <typedefs.h>
#include <hw_io.h>
#include <macros.h>

static void enable_a20_fast(void)   { outpb(0x92, (inpb(0x92) | 0x02) & ~1); }
static void wait_kbdc(void)         { while (inpb(0x64) & 2) { io_delay(); } }
static void discard_kbdc_data(void) { while ((inpb(0x64) & 1)) { io_delay(); (void)inpb(0x60); } }

static _Bool enable_a20_int15h(void)
{
  _Bool r;

  __asm__ __volatile__ (
    "movw %1,%%ax\n"
    "int 0x15\n"
    "movb $0,%%al\n"
    "setc al"
    : "=a" (r) : "i" ((_u16)0x2401)
  );

  return r;
}

static void enable_a20_kbdc(void)
{
  wait_kbdc(); outpb(0x64, 0xad);   // turn kbd off.
  wait_kbdc(); outpb(0x64, 0xd0);   // read output port.

  discard_kbdc_data();              // discard output data.

  wait_kbdc(); outpb(0x64, 0xd1);   // write output port.
  wait_kbdc(); outpb(0x60, 0xdf);   // a20 on! (FIXME: system reset too?!)
  wait_kbdc(); outpb(0x64, 0xae);   // turn kbd back on.
  wait_kbdc();
}

static _Bool check_a20(void)
{
  _u8 orig, lo;
  _Bool r = true;

  // it's ok to pollute fs and gs...
  set_fs(0);
  set_gs(0xffff);

  orig = rd_fs8(0x500); // read 0:0x500.
  wr_gs8(0x510, ~orig); // write its inverse in 0xffff:0x510
  lo = rd_fs8(0x500);   // read 0:0x500 again.
  if (orig == lo)       // if equal, a20 not enabled!
    r = false;
  wr_fs8(0x500, orig);  // puts 0:0x500 original value back.
  return r;    
}

_Bool enable_a20(void)
{
  _Bool r = true;

  if (!enable_a20_int15h()) // if int 0x15 fails...
  {
    /* FIXME: Should we test fast first? */

    enable_a20_kbdc();      // try legacy code.
    if (!check_a20())       // a20 not set?
    {
      enable_a20_fast();    // try fast code.
      r = check_a20();      // test a20 again.
    }
  }

  return r;
}

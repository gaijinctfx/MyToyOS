// 16 bits code.
#include "typedefs.h"
#include "hw_io.h"
#include "macros.h"

static void enable_a20_fast(void)
{ outpb(0x92, (inpb(0x92) | 0x02) & ~1); }

static void wait_kbdc(void)
{ while (inpb(0x64) & 2) { io_delay(); } }

static void discard_kbdc_data(void)
{ while ((inpb(0x64) & 1)) { io_delay(); (void)inpb(0x60); } }

static void enable_a20_kbdc(void)
{
  wait_kbdc(); outpb(0x64, 0xad);   // turn kbd off.
  wait_kbdc(); outpb(0x64, 0xd0);   // read output port.

  discard_kbdc_data();              // discard output data.

  wait_kbdc(); outpb(0x64, 0xd1);   // write output port.
  wait_kbdc(); outpb(0x60, 0xdf);   // a20 on! (system reset too?!)
  wait_kbdc(); outpb(0x64, 0xae);   // turn kbd back on.
  wait_kbdc();
}

static _Bool check_a20(void)
{
  _u8 tmp, hi;

  // it's ok to pollute fs and gs...
  set_fs(0);
  set_gs(0xffff);

  tmp = rd_fs8(0x500);
  if (tmp != (hi = rd_gs8(0x510)))
    return true;
  wr_gs8(0x510, ~hi);
  if (rd_fs8(0x500) == hi)
  {
    wr_fs8(0x500, tmp);
    return false;
  }
  wr_fs8(0x500, tmp);
  return true;    
}

_Bool enable_a20(void)
{
  _Bool r = true;

  // FIXME: Maybe this is unecessary here!
  disable_ints();

  enable_a20_fast();
  if (!check_a20())
  {
    enable_a20_kbdc();
    r = check_a20();
  }

  // FIXME: Maybe this is unecessary here!
  enable_ints();

  return r;
}

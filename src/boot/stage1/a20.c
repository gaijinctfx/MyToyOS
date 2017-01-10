// 16 bits code.
#include "typedefs.h"
#include "hw_io.h"
#include "macros.h"

extern _Bool check_a20(void);

static void enable_a20_fast(void)
{
  _u8 cpa;

  cpa = inpb(0x92);
  if (!(cpa & 0x02))
    outpb(0x92, cpa | 0x02);
}

static void wait_a20_1(void)
{ while (inpb(0x64) & 2); }

static void wait_a20_2(void)
{ while (!(inpb(0x64) & 1)); }

static void enable_a20_kbdc(void)
{
  _u8 k;

  wait_a20_1(); outpb(0x64, 0xad);
  wait_a20_1(); outpb(0x64, 0xd0);
  wait_a20_2();
  k = inpb(0x60);
  wait_a20_1(); outpb(0x64, 0xd1);
  wait_a20_1(); outpb(0x60, k | 2);
  wait_a20_1(); outpb(0x64, 0xae);
  wait_a20_1();
}

_Bool enable_a20(void)
{
  _Bool r = true;

  disable_ints();

  enable_a20_fast();
  if (!check_a20())
  {
    enable_a20_kbdc();
    r = check_a20();
  }

  enable_ints();

  return r;
}

// 32 bit code

#include <typedefs.h>

#define KERNEL_BASE_ADDR  0x100000UL

static _u32 get_kernel_first_fat_block(_u8, _u32);
static _u32 get_kernel_next_fat_block(_u8, _u32);

int load_kernel(_u8 drive, _u64 sblk)
{
  int r = 0;
  _u32  num_blocks = 0;
  _u32  addr = KERNEL_BASE_ADDR;
  _u32  block;

  block = get_kernel_first_fat_block(drive, sblk);
  for (; block != -1; num_blocks++, addr += 4096)
  {
    if (read_sectors(drive, block, 8, (void *)addr, &did))
    {
      r = 1;
      break;
    }

    block = get_kernel_next_fat_block(drive, sblk, block);
  }

  if (!r || !num_blocks)
    r = 1;

  return r;
}

_Noreturn void load_kernel_error(void)
{
  puts("Error loading kernel");

  __asm__ __volatile__ (
    "1: hlt\n"
    "   jmp 1b"
  );
}

_u32 get_kernel_first_fat_block(_u8 drive, _u32 sblk)
{
}

_u32 get_kernel_next_fat_block(_u8 drive, _u32 sblk, _u32 block)
{
}


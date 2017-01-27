// 32 bit code

#include <typedefs.h>

int load_kernel(_u8 drive, _u64 boot_start_addr, _u32 boot_blocks)
{
  return 0;   // return OK.
}

_Noreturn void load_kernel_error(void)
{
  puts("Error loading kernel");

  __asm__ __volatile__ (
    "1: hlt\n"
    "   jmp 1b"
  );
}

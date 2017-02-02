#include <typedefs.h>

char *strcpy(char *dest, char *src)
{
  char *p = dest;

  while (*dest++ = *src++);

  return p;
}

_u32 strlen(char *src)
{
  _u32 size = (_u32)-1;

  __asm__ __volatile__ (
    "xorb %%al,%%al\n"
    "repnz; scasb"
    : "=c" (size)
    : "D" (src)
    : "eax"
  );

  return ~size - 1;
}

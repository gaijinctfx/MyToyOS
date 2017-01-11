#include <typedefs.h>

_u8 current_x, current_y;

void screen_setup(void)
{
  _u8 *p = MK_FP(0, 0x450);
  current_x = *p++;
  current_y = *p;
}

void clear_screen(void)
{
  __asm__ __volatile__ (
    "cld\n"
    "rep; stosw" :
    : "a" ((_u16)0x0720), "S" (0xb8000), "c" (4000)
  );

  current_x = current_y = 0;
}

void scroll_up(void)
{
  __asm__ __volatile__ (
    "movl $0xb8000,%%edi\n"

    // scroll up
    "movl %%edi,%%esi\n"
    "add  $160,%%esi\n"
    "movl $1920,%%ecx\n"    // 1920 words.
    "cld\n"
    "rep; movsw\n"

    // clear last line.
    "movw $0x0720,%%ax\n"
    "mov  $80,%%ecx\n"
    "rep; stosw\n" : : : "edi", "esi"
  );
}

void putchar(char c)
{
  _u8 *ptr = (_u8 *)0xb8000 + 160 * current_y + 2*current_x;

  switch (c)
  {
    case '\n':  current_y++; goto update_y;
    case '\r':  current_x = 0; break;
  }

  *ptr++ = 0x07;
  *ptr = c;

  if (++current_x >= 80)
  {
    current_x = 0;
    current_y++;
  }

update_y:
  if (current_y > 24)
  {
    scroll_up();
    current_y = 24;
  }
}

void puts(char *s)
{
  for (; *s; s++)
    putchar(*s);
}

void gotoxy(_i8 x, _i8 y)
{
  if (x < 0) x = 0;
  if (x >= 80) x = 79;
  if (y < 0) y = 0;
  if (y >= 25) y = 24;
  current_x = x;
  current_y = y;
}

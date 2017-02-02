#include <typedefs.h>
#include <macros.h>

_u8 current_x, current_y;
_u8 current_attrib = 0x07;

void screen_setup(void)
{
  _u8 *p = MK_FP(0, 0x450);
  current_x = *p++;
  current_y = *p;
  current_attrib = (_u8 *)MK_FP(0, 0x48a);  // is this correct?
}

void clear_screen(void)
{
  _u16 b = ' ' | ((_u16)current_attrib << 8);

  __asm__ __volatile__ (
    "rep; stosw" :
    : "a" (b), "S" (0xb8000), "c" (4000)
  );

  current_x = current_y = 0;
}

void scroll_up(void)
{
  _u16 b = ' ' | ((_u16)current_attrib << 8);

  __asm__ __volatile__ (
    "movl $0xb8000,%%edi\n"

    // scroll up
    "movl %%edi,%%esi\n"
    "add  $160,%%esi\n"
    "movl $1920,%%ecx\n"    // 1920 words.
    "rep; movsw\n"

    // clear last line.
    "mov  $80,%%ecx\n"
    "rep; stosw\n" : : "a" (b) : "edi", "esi", "ecx"
  );
}

void putchar(char c)
{
  _u8 *ptr = (_u8 *)0xb8000 + 2*(80*current_y + current_x);

  switch (c)
  {
    case '\n':  current_y++; goto update_y;
    case '\r':  current_x = 0; break;
  }

  *ptr++ = current_attrib;
  *ptr = c;

  if (++current_x > 79)
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
  if (x > 79) x = 79;
  if (y < 0) y = 0;
  if (y > 24) y = 24;
  current_x = x;
  current_y = y;
}

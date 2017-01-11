/* 16 bit code. */
void real_puts(char *s)
{
  for (; *s; s++)
    __asm__ __volatile__ ( "movb $0x0e,%%ah\n"
                           "int 0x13" : : "a" (*s));
}

char *strcpy(char *dest, char *src)
{
  while (*dest++ = *src++);
}

_u32 strlen(char *src)
{
  _u32 size = 0;

  while (*src++) 
    size++;

  return size;
}

#include <hw_io.h>
#include <screen.h>

void __attribute__((interrupt)) gpf_intr(void)
{
  puts("[!] General Protection Fault! System Halted.");

  // FIXME: Probably not a good idea!
  halt();
}

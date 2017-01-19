#include <typedefs.h>
#include <hw_io.h>
#include <io_ports.h>

void mask_irq(unsigned int irq)
{
  _u8 mask;

  if (irq < 8)
  {
    mask = inpb(PIC0_OCW1) & 0xfb;  // irq2 always unmasked.
    mask |= 1 << irq;
    outpb(PIC0_OCW1, mask);
  }
  else
  {
    mask = inpb(PIC1_OCW1);
    mask |= 1 << (irq - 8);
    outpb(PIC1_OCW1, mask);
  }
}

void unmask_irq(unsigned int irq)
{
  _u8 mask;

  if (irq < 8)
  {
    mask = inpb(PIC0_OCW1);
    mask &= ~(1 << irq) | 0xfb;   // irq2 always unmasked.
    outpb(PIC0_OCW1, mask);
  }
  else
  {
    mask = inpb(PIC1_OCW1);
    mask &= ~(1 << (irq - 8));
    outpb(PIC1_OCW1, mask);
  }
}

// BC++3.1 read_geom.c
#include <stdio.h>
#include <dos.h>

// Disk Access Paramater Table
struct dap_s {
  unsigned short size;
  unsigned short count;
  unsigned short ofs, seg;
  unsigned long  lba_lo, lba_hi;
};

// Partition Table Entry.
struct geom_s {
};

int get_disk_geometry(unsigned char, struct geom_s *);

int main(void)
{
  if (get_disk_geometry(0x80, &g))
  {
    fpurs("Error reading MBR!\n", stderr);
    return 1;
  }

  // Show partition table entry.

}

int get_disk_geometry(unsigned char drive, struct geom_s *g)
{
  struct dap_s dap;
  union REGS regs;
  struct SREGS sregs;

  dap.size = sizeof(struct dap_s);
  dap.count = 1;
  dap.ofs = FP_OFF(g);
  dap.seg = FP_SEG(g);
  dap.lba_lo = dap.lba_hi = 0;  // mbr.

  regs.h.ah = 0x42;
  regs.x.bx = FP_OFF(&dap);
  sregs.es = FP_SEG(&dap);
  int86x(0x13, &regs, &regs, &sregs);
  return !!regs.cflag;
}

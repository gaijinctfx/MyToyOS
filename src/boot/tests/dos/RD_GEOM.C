// BC++3.1 read_geom.c
#include <stdio.h>
#include <dos.h>

// Disk Access Paramater Table
struct dap_s {
  unsigned int size;
  unsigned int count;
  unsigned int ofs, seg;
  unsigned long  lba_lo, lba_hi;
};

// Partition Table Entry.
struct geom_s {
  unsigned char status;
  unsigned char start_chs[3];
  unsigned char type;
  unsigned char end_chs[3];
  unsigned long lba;          // only lba28 supported?
  unsigned long sectors;
};

int get_disk_geometry(unsigned char, void *);

unsigned char buffer[512];

int main(void)
{
  struct geom_s *p;

  if (get_disk_sector(0x80, buffer))
  {
    fpurs("Error reading MBR!\n", stderr);
    return 1;
  }

  p = (struct geom_s *)(((char *)buffer)+0x1be);

  // Show partition table entry.
  printf("LBA: %lu, sectors: %lu\n", p->lba, p->sectors);
}

int get_disk_sector(unsigned char drive, void *buffer)
{
  struct dap_s dap;
  union REGS regs;
  struct SREGS sregs;

  dap.size = sizeof(struct dap_s);
  dap.count = 1;
  dap.ofs = FP_OFF(buffer);
  dap.seg = FP_SEG(buffer);
  dap.lba_lo = dap.lba_hi = 0;  // mbr.

  regs.h.ah = 0x42;
  regs.h.dl = drive;
  regs.x.si = FP_OFF(&dap);
  sregs.ds = FP_SEG(&dap);
  int86x(0x13, &regs, &regs, &sregs);
  return !!regs.cflag;
}

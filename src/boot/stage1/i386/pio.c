// stage1 32bit pm disk i/o routines.
//
// gcc -O3 -m32 -ffreestanding -nostdlib -S pio.c
//
#include <typedefs.h>
#include <hw_io.h>

struct device_id_s {
  _Bool   supports_lba;
  _Bool   supports_lba48;

  _u8 max_xfer_sectors;
};

// 
static const _u16 hdd_io_ports[4] = { 0x1f0, 0x1f0, 0x170, 0x170 };

extern _u16 calc_chksum16(void *, _u32);

// OBS; DS=ES=SS.
static inline void _rdblocks(_u8 count, void *ptr)
{ __asm__ __volatile__( "rep; insw" : : "S" (ptr), "c" ((_u32)count * 256) ); }

static inline void _delay400ns(_u16 port)
{ (void)inpb(port+7);
  (void)inpb(port+7); 
  (void)inpb(port+7); 
  (void)inpb(port+7);  }

// 0x3f6 = primary controller on local bus DCR (Device Control Register).
// sets the SRST bit. A command will reset it.
static inline void _softreset(void)
{ outpb(0x3f6, inpb(0x3f6) | 0x4); }

int identify_device(_u8 disk, struct device_id_s *did_ptr)
{
  _u8 buffer[256];

  _u16 port, csum;
  _u8  status;

  if (!(disk & 0x80))
    return 1;

  port = hdd_io_ports[disk & 3];

  _softreset();

  // Set device, and issue command.
  outpb(port+6, (disk << 3) & 0x10);
  outpb(port+7, 0xec);    // send IDENTIFY_DEVICE cmd.

  // Wait for !BUSY & DRDY.
  _delay400ns(port);
  while (((status = inpb(port+7)) & 0xc0) != 0x40);

  // Is there an error?!
  if (status & 1)
    return 1;

  _rdblocks(1, buffer);
      
  // If isn't ATA, return with error.
  if (buffer[0] & 0x8000)
    return 1;

  // test the checksum.
  csum = calc_chksum16(buffer, 510);
  if (csum != buffer[255])
    return 1;

  did_ptr->supports_lba = ((buffer[49] & 0x100) != 0);
  did_ptr->supports_lba48 = ((buffer[83] & 0x400) != 0);
  did_ptr->max_xfer_sectors = buffer[47] & 0xff;

  return 0;
}

int read_sectors(_u8 disk, _u64 start, _u8 sectors_count, void *buffer)
{
  _u16 port;
  _u8 device;
  _u8 status;

  if (!(disk & 0x80))
    return 1;

  port = hdd_io_ports[disk & 3];
  device = ((disk << 3) | 0x40) & 0x50;

  _softreset();

  if (start > 0xfffffff)
  {
    outpb(port+2, 0);
    outpb(port+3, (start >> 24) & 0xff);
    outpb(port+4, (start >> 32) & 0xff);
    outpb(port+5, (start >> 40) & 0xff);

    outpb(port+2, sectors_count);
    outpb(port+3, (start & 0xff));
    outpb(port+4, (start >> 8) & 0xff);
    outpb(port+5, (start >> 16) & 0xff);

    outpb(port+6, device);
    outpb(port+7, 0x24);    // READ_SECTORS_EXT
  }
  else
  {
    outpb(port+2, sectors_count);
    outpb(port+3, start & 0xff); start >>= 8;
    outpb(port+4, start & 0xff); start >>= 8;
    outpb(port+5, start & 0xff); start >>= 8;
    outpb(port+6, device | (start & 0x0f));
    outpb(port+7, 0x20);    // READ_SECTORS
  }

  _delay400ns(port);
  while (((status = inpb(port+7)) & 0xc0) != 0x40);

  if (status & 1)
    return 1;

  _rdblocks(sectors_count, buffer);

  return 0;
}


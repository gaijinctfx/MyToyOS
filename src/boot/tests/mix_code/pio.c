// gcc -O3 -m16 -ffreestanding -nostdlib -S pio.c
#include "hw_io.h"

struct device_id_s {
  int   supports_lba:1;
  int   supports_lba48:1;

  uint8_t max_xfer_sectors;
};

static uint16_t hdd_io_ports[4] = { 0x1f0, 0x1f0, 0x170, 0x170 };

int identify_device(uint8_t disk, struct device_id_s *did_ptr)
{
  uint8_t buffer[256], *ptr;

  uint16_t port;
  uint8_t  status;
  int      count;
  _Bool     isATA;

  if (!(disk & 0x80))
    return 1;

  port = hdd_io_ports[disk & 3];

  // Set device, and issue command.
  outpb(port+6, (disk << 3) & 0x10);
  outpb(port+7, 0xec);    // send IDENTIFY_DEVICE cmd.

  // Wait for !BUSY & DRDY.
  while (((status = inpb(port+7)) & 0xc0) != 0x40);

  // Is there an error?!
  if (status & 1)
    return 1;

  ptr = buffer;
  count = 256;
  while (count--)
    *ptr++ = inpw(port);
      
  if (buffer[0] & 0x8000)
    return 1;

  did_ptr->supports_lba = (buffer[49] & 0x100);
  did_ptr->supports_lba48 = buffer[83] & 0x400;
  did_ptr->max_xfer_sectors = buffer[47] & 0xff;

  return 0;
}

int read_sectors(uint8_t disk, uint64_t start, uint8_t sectors_count, void *buffer)
{
  uint16_t *ptr = buffer;
  uint16_t port;
  uint8_t device;
  uint8_t status;
  uint32_t count;
  _Bool isLBA48;

  if (!(disk & 0x80))
    return 1;

  port = hdd_io_ports[disk & 3];

  device = ((disk << 3) | 0x40) & 0x50;
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

  while (((status = inpb(port+7)) & 0xc0) != 0x40);

  if (status & 1)
    return 1;

  count = sectors_count * 256;
  while (count--)
    *ptr++ = inpw(port);

  return 0;
}

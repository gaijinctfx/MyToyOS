#ifndef __pio_h__
#define __pio_h__

struct device_id_s {
  _Bool   supports_lba;
  _Bool   supports_lba48;

  _u8 max_xfer_sectors;
};

extern int identify_device(_u8, struct device_id_s *);
extern int read_sectors(_u8, _u64, _u8, void *, struct device_id_s *);

#endif

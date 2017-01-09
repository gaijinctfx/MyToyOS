uint16_t calc_cksum16(uint8_t *buffer, uint32_t size)
{
  uint32_t sum = 0;

  while (size--)
    sum += *buffer++;

  if (sum > 0xffff)
    sum += (sum >> 16);

  return sum & 0xffff;
}

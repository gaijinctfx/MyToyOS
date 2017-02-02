#include <typedefs.h>

struct cpu_features_s {
  _u32 pse:1;
  _u32 pae:1;
  _u32 pge:1;
  _u32 pat:1;
  _u32 pse36:1;
  _u32 pcid:1;

  _u32 nx:1;
  _u32 pg1g:1;
  _u32 lm:1;

  _u8 maxphysaddr_bits;
  _u8 maxlinearaddr_bits;
};

static struct cpu_features_s cpu_features;

void get_cpu_features(void)
{
  _u32 a, c, d;

  __asm__ __volatile__ ( "cpuid" : "=c" (c), "=d" (d) : "a" (1) : "ebx" );
  cpu_features.pse = (d & (1U << 3)) != 0;
  cpu_features.pae = (d & (1U << 6)) != 0;
  cpu_features.pge = (d & (1U << 13)) != 0;
  cpu_features.pat = (d & (1U << 16)) != 0;
  cpu_features.pse36 = (d & (1U << 17)) != 0;
  cpu_features.pcid = (c & (1U << 17)) != 0;

  __asm__ __volatile__ ( "cpuid" : "=a" (a), "=d" (d) : "0" (0x80000001U) : "ebx" );
  cpu_features.nx = (d & (1U << 20)) != 0;
  cpu_features.pg1g = (d & (1U << 26)) != 0;
  cpu_features.lm = (d & (1U << 29)) != 0;

  __asm__ __volatile__ ( "cpuid" : "=a" (a) : "0" (0x80000008U) : "ebx", "edx" );
  cpu_features.maxphysaddr_bits = (a & 0xff);
  cpu_features.maxphysaddr_bits = ((a >> 8) & 0xff);
}

_Bool cpu_supports_lm(void) { return cpu_features.lm; }
_Bool cpu_supports_pae(void) { return cpu_features.pae; }
_Bool cpu_supports_pse(void) { return cpu_features.pse; }
_Bool cpu_supports_nx(void) { return cpu_features.nx; }

_u64 cpu_maxphysaddr(void) { return (1ULL << cpu_features.maxphysaddr_bits) - 1ULL; }

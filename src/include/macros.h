#ifndef __macros_h__
#define __macros_h__

#include <typedefs.h>

// 16 (segment:offset) -> 32 bits offset.
#define MK_FP(s,o) ((void *)(((_u32)(s) << 4) + ((_u32)(o))))

#endif

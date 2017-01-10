#ifndef __hw_io_h__
#define __hw_io_h__

#include "typedefs.h"

inline void disable_ints(void) { __asm__ __volatile__ ("cli"); }
inline void enable_ints(void) { __asm__ __volatile__ ("sti"); }

inline void outpb(_u16 port, _u8 data) { __asm__ __volatile__( "outb %0,%1" : : "a" (data), "dN" (port)); }
inline void outpw(_u16 port, _u16 data) { __asm__ __volatile__( "outw %0,%1" : : "a" (data), "dN" (port)); }
inline void outpd(_u16 port, _u32 data) { __asm__ __volatile__( "outl %0,%1" : : "a" (data), "dN" (port)); }

inline _u8 inpb(_u16 port) { _u8 data; __asm__ __volatile__( "inb %1,%0" : "=a" (data) : "dN" (port)); return data; }
inline _u16 inpw(_u16 port) { _u16 data; __asm__ __volatile__( "inw %1,%0" : "=a" (data) : "dN" (port)); return data; }
inline _u32 inpd(_u16 port) { _u32 data; __asm__ __volatile__( "inl %1,%0" : "=a" (data) : "dN" (port)); return data; }

// Stolen from limux! :)
inline void io_delay(void) { __asm__ __volatile__ ( "outb %%al,$0x80" ); }
inline void set_es(_u16 seg) { __asm__ __volatile__ ( "movw %0,%%es" : : "rm" (seg) ); }
inline void set_fs(_u16 seg) { __asm__ __volatile__ ( "movw %0,%%fs" : : "rm" (seg) ); }
inline void set_gs(_u16 seg) { __asm__ __volatile__ ( "movw %0,%%gs" : : "rm" (seg) ); }
inline _u16 _ds(void) { _u16 seg; __asm__ __volatile__ ( "movw %%ds,%0" : "=rm" (seg) ); return seg; }
inline _u16 _es(void) { _u16 seg; __asm__ __volatile__ ( "movw %%es,%0" : "=rm" (seg) ); return seg; }
inline _u16 _fs(void) { _u16 seg; __asm__ __volatile__ ( "movw %%fs,%0" : "=rm" (seg) ); return seg; }
inline _u16 _gs(void) { _u16 seg; __asm__ __volatile__ ( "movw %%gs,%0" : "=rm" (seg) ); return seg; }

inline _u8 rd_es8(_u16 addr)   { _u8 t;  __asm__ __volatile__ ( "movb %%es:%1,%0" : "=q" (t) : "m" (*(_u8 *)addr) ); return t; }
inline _u8 rd_fs8(_u16 addr)   { _u8 t;  __asm__ __volatile__ ( "movb %%fs:%1,%0" : "=q" (t) : "m" (*(_u8 *)addr) ); return t; }
inline _u8 rd_gs8(_u16 addr)   { _u8 t;  __asm__ __volatile__ ( "movb %%gs:%1,%0" : "=q" (t) : "m" (*(_u8 *)addr) ); return t; }
inline _u16 rd_es16(_u16 addr) { _u16 t; __asm__ __volatile__ ( "movw %%es:%1,%0" : "=r" (t) : "m" (*(_u16 *)addr) ); return t; }
inline _u16 rd_fs16(_u16 addr) { _u16 t; __asm__ __volatile__ ( "movw %%fs:%1,%0" : "=r" (t) : "m" (*(_u16 *)addr) ); return t; }
inline _u16 rd_gs16(_u16 addr) { _u16 t; __asm__ __volatile__ ( "movw %%gs:%1,%0" : "=r" (t) : "m" (*(_u16 *)addr) ); return t; }
inline _u32 rd_es32(_u16 addr) { _u32 t; __asm__ __volatile__ ( "movl %%es:%1,%0" : "=r" (t) : "m" (*(_u32 *)addr) ); return t; }
inline _u32 rd_fs32(_u16 addr) { _u32 t; __asm__ __volatile__ ( "movl %%fs:%1,%0" : "=r" (t) : "m" (*(_u32 *)addr) ); return t; }
inline _u32 rd_gs32(_u16 addr) { _u32 t; __asm__ __volatile__ ( "movl %%gs:%1,%0" : "=r" (t) : "m" (*(_u32 *)addr) ); return t; }

inline void wr_es8(_u16 addr, _u8 data)   { __asm__ __volatile__ ( "movb %0,%%es:%1" : : "qi" (data), "m" (*(_u8 *)addr) ); }
inline void wr_fs8(_u16 addr, _u8 data)   { __asm__ __volatile__ ( "movb %0,%%fs:%1" : : "qi" (data), "m" (*(_u8 *)addr) ); }
inline void wr_gs8(_u16 addr, _u8 data)   { __asm__ __volatile__ ( "movb %0,%%gs:%1" : : "qi" (data), "m" (*(_u8 *)addr) ); }
inline void wr_es16(_u16 addr, _u16 data) { __asm__ __volatile__ ( "movw %0,%%es:%1" : : "ri" (data), "m" (*(_u16 *)addr) ); }
inline void wr_fs16(_u16 addr, _u16 data) { __asm__ __volatile__ ( "movw %0,%%fs:%1" : : "ri" (data), "m" (*(_u16 *)addr) ); }
inline void wr_gs16(_u16 addr, _u16 data) { __asm__ __volatile__ ( "movw %0,%%gs:%1" : : "ri" (data), "m" (*(_u16 *)addr) ); }
inline void wr_es32(_u16 addr, _u32 data) { __asm__ __volatile__ ( "movl %0,%%es:%1" : : "ri" (data), "m" (*(_u32 *)addr) ); }
inline void wr_fs32(_u16 addr, _u32 data) { __asm__ __volatile__ ( "movl %0,%%fs:%1" : : "ri" (data), "m" (*(_u32 *)addr) ); }
inline void wr_gs32(_u16 addr, _u32 data) { __asm__ __volatile__ ( "movl %0,%%gs:%1" : : "ri" (data), "m" (*(_u32 *)addr) ); }

#endif

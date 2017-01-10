#ifndef __hw_io_h__
#define __hw_io_h__

#include "typedefs.h"

void inline outpb(_u16 port, _u8 data)
{ __asm__ __volatile__( "outb %0,%1" : : "a" (data), "dN" (port)); }

void inline outpw(_u16 port, _u16 data)
{ __asm__ __volatile__( "outw %0,%1" : : "a" (data), "dN" (port)); }

_u8 inline inpb(_u16 port)
{ _u8 data; __asm__ __volatile__( "inb %1,%0" : "=a" (data) : "dN" (port)); return data; }

_u16 inline inpw(_u16 port)
{ _u16 data; __asm__ __volatile__( "inw %1,%0" : "=a" (data) : "dN" (port)); return data; }

#endif

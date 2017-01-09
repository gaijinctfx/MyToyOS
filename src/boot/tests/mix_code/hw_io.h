#ifndef __hw_io_h__
#define __hw_io_h__

#include <stdint.h>

void inline outpb(uint16_t port, uint8_t data)
{ __asm__ __volatile__( "outb %0,%1" : : "a" (data), "dN" (port)); }

void inline outpw(uint16_t port, uint16_t data)
{ __asm__ __volatile__( "outw %0,%1" : : "a" (data), "dN" (port)); }

uint8_t inline inpb(uint16_t port)
{ uint8_t data; __asm__ __volatile__( "inb %1,%0" : "=a" (data) : "dN" (port)); return data; }

uint16_t inline inpw(uint16_t port)
{ uint16_t data; __asm__ __volatile__( "inw %1,%0" : "=a" (data) : "dN" (port)); return data; }

#endif

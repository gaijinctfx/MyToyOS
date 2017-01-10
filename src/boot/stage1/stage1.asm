bits 16

; This section will begin at 0x60:0.
section .text

global _start
extern _main

_start:
  mov   ax,cs
  mov   ds,ax
  mov   es,ax
  mov   esp,0xfffc    ; To be sure we are at stack top.
  jmp   _main

; 32 bit code.
bits 32

global  jmp2kernel
jmp2kernel:
  jmp   8:0x100000

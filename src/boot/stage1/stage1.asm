bits 16

; This section will begin at 0x60:0.
section .text

global _start

extern _main
extern _bss_start
extern _bss_end

_start:
  mov   ax,cs
  mov   ds,ax
  mov   es,ax
  mov   esp,0xfffc    ; To be sure we are at stack top.

  ; Clean up bss section
  mov   edi,_bss_start
  mov   ecx,_bss_end
  sub   ecx,edi
  jz    .nothing_to_cleanup
  xor   al,al
  cld
  rep   stosb
.nothing_to_cleanup:
  jmp   _main

; 32 bit code.
bits 32

struc calc_csum16_stk
.bufferptr: resd  1
.size:      resd  1
endstruc

global  calc_chksum16
calc_chksum16:
  mov   ecx,[esp+calc_csum16_stk.size]
  mov   esi,[esp+calc_csum16_stk.bufferptr]
  xor   edx,edx
  xor   eax,eax
  cld
  test  ecx,ecx
.loop:
  jz    .loop_end
  mov   dl,[esi]
  add   ax,dx
  adc   ax,0
  inc   esi
  dec   ecx
  jmp   .loop
.loop_end:
  ret  

global  jmp2kernel
jmp2kernel:
  jmp   8:0x100000

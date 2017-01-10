section .data

extern gdt_desc

; This section will begin at 0x60:0.
section .text

global _start

extern _main32
extern setup_pm

extern _bss_start
extern _bss_end

bits 16

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
  call  setup_pm

  ; TODO...

  lgdt  [gdt_desc]
  mov   eax,cr0
  or    eax,1
  mov   cr0,eax

  jmp   8:_main       ; Jumps to protected mode.


global check_a20
check_a20:
  push  ds
  push  es
  xor   dx,dx
  mov   ds,dx
  mov   ax,-1
  mov   es,ax

  mov   cl,[0x500]    ; saves 0:0x500 byte.
  mov   al,[es:0x510]
  not   al
  mov   [0x500],al
  mov   dl,[es:0x510]
  xor   al,dl
  sete  al
  mov   [0x500],cl

  pop   es
  pop   ds
  ret

global  real_puts
; void real_puts(char *);
real_puts:
  cld
  mov   si,[esp+4]
.loop:
  lodsb
  test  al,al
  jz    .exit
  mov   ah,0x0e
  int   0x10
  jmp   .loop
.exit:
  ret

; 32 bit code.
bits 32

_main:
  mov   ax,0x10
  mov   ds,ax
  mov   es,ax
  mov   ss,ax
  mov   esp,0x9fffc   ; ESP back to lower RAM top.
  call  _main32
  jmp   8:0x100000    ; jumps to kernel.

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
.loop:
  test  ecx,ecx
  jz    .loop_end
  mov   dl,[esi]
  add   ax,dx
  adc   ax,0
  inc   esi
  dec   ecx
  jmp   .loop
.loop_end:
  ret  


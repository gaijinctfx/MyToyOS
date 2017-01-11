section .data

extern gdt_desc

; This section will begin at 0x60:0.
section .text

extern _bss_start
extern _bss_end
extern _main32
extern setup_pm

bits 16

global _start
_start:
  mov   ax,cs
  mov   ds,ax
  mov   es,ax
  mov   esp,0xfffc    ; To be sure we are at stack top.
                      ; SS still points to 0x9000.

  ; Clears bss section
  mov   edi,_bss_start
  mov   ecx,_bss_end
  sub   ecx,edi       ; ECX is the size, in bytes.
  jz    .nothing_to_clear
  xor   al,al
  cld
  rep   stosb         ; Fill with zeroes.
.nothing_to_clear:
  call  setup_pm
  test  eax,eax
  jnz   halt

  ; TODO...

  cli                 ; No interrupts.
  lgdt  [gdt_desc]
  mov   eax,cr0
  or    eax,1
  mov   cr0,eax
  jmp   8:_main       ; Jumps to protected mode.

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
  call  _main32       ; _main32 will load the kernel!
  test  eax,eax       ; Returns 0 if OK, 1 if error.
  jnz   goto_kernel
halt:
  hlt
  jmp   halt 
goto_kernel:
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


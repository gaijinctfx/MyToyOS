section .bss

global drivenum
global boot_start_addr
global boot_blocks

drivenum:         resb  1
boot_start_addr:  resq  1
boot_blocks:      resd  1

section .data

extern gdt_desc

  align 4
empty_idt:  dw  0
            dd  0

; This section will begin at 0x60:0.
section .text

extern _bss_start
extern _bss_end
extern load_kernel
extern load_kernel_error
extern setup_pm
extern mask_all_irqs
extern mask_nmi

;-------------------------------
; 16 bit code.
;-------------------------------
bits 16

global _start
; Enters here with EBX:EAX = boot_start_lba48
;                  ECX = number of boot blocks.
;                  DL = drivenum.
_start:
  mov   ax,cs
  mov   ds,ax
  mov   es,ax
  mov   esp,0xfffc    ; To be sure we are at stack top.
                      ; SS still points to 0x9000.

  ; Clears bss section
  push  eax
  push  ecx
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
  pop   ecx
  pop   eax
  jz    .continue

.halt:
  hlt
  jmp   .halt

.continue:
  ; Save entry info.
  mov   [drivenum],dl
  mov   [boot_start_addr],eax
  mov   [boot_start_addr+4],ebx
  mov   [boot_blocks],ecx

  ; TODO...

  cli                 ; No interrupts!

  call  mask_all_irqs
  call  mask_nmi

  ; Setup empty idt.
  lidt  [empty_idt]

  ; Setup task state segment (recomended by Intel).

  ; Setup gdt and jumps to protected mode.
  lgdt  [gdt_desc]
  mov   eax,cr0
  or    eax,1
  mov   cr0,eax
  jmp   8:_main       ; Jumps to protected mode.

global  r_puts
; void r_puts(char *);
r_puts:
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

bits 32

  align 4
_main:
  mov   ax,0x10       ; Default data segment.
  mov   ds,ax
  mov   es,ax
  mov   ss,ax
  mov   esp,0x9fffc   ; set ESP back to lower RAM top.

  ; ret = loadkernel(drivenum, boot_start_addr, boot_blocks);
  push  dword [boot_blocks]
  ; FIXME: Possibly I could add 8 sectors here beforehand.
  ;        The kernel is just after this code's block.
  push  dword [boot_start_addr+4]   ; highest dword first.
  push  dword [boot_start_addr]
  movzx eax,byte [drivenum]
  push  eax
  call  load_kernel

  test  eax,eax       ; if returns 0, kernel is loaded.
  jnz   .load_error

  ; FIXME: What should I pass to the kernel here?
  jmp   8:0x100000    ; jumps to kernel.
.load_error:
  jmp   load_kernel_error

;-------------------
; Smaller routine used by protected mode C code.
;-------------------
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
  adc   ax,0          ; Let ADC accumulate the carry-outs...
  inc   esi
  dec   ecx
  jmp   .loop
.loop_end:
  ret  


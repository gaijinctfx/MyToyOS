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
;                  ECX = number of boot blocks to read.
;                  DL = drivenum.
_start:
  mov   ax,cs
  mov   ds,ax
  mov   es,ax
  mov   esp,0xfffc    ; To be sure we are at stack top.
                      ; SS still points to 0x9000.

  ; Save entry data.
  mov   [boot_start_addr],eax
  mov   [boot_start_addr+4],ebx
  mov   [boot_blocks],ecx
  mov   [drivenum],dl

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
  jz    .continue

.halt:
  hlt
  jmp   .halt

.continue:
  ; TODO...

  cli                 ; No interrupts!
  call  mask_all_irqs
  call  mask_nmi

  ; Setup empty idt.
  lidt  [empty_idt]

  ; TODO: Setup task state segment (recomended by Intel).

  ; Setup gdt and jumps to protected mode.
  lgdt  [gdt_desc]
  mov   eax,cr0
  or    eax,1         ; Set Protecting Enabled bit.
  mov   cr0,eax
  jmp   8:_main       ; Jumps to protected mode code below.

; Ok... this is replicated here, but now is a 32 bit C function.
;
; void r_puts(char *);
;
; Will be used by 16 bit C code.
struc r_puts_stk
.oldebp:  resd  1
.retaddr: resw  1
.ptr:     resd  1
endstruc

global  r_puts
r_puts:
  push  ebp
  mov   ebp,esp
  cld
  mov   esi,[ebp+r_puts_stk.ptr]
.loop:
  lodsb
  test  al,al
  jz    .exit
  mov   ah,0x0e
  int   0x10
  jmp   .loop
.exit:
  pop   ebp
  ret

;==========================================
; 32 Bit protected mode code.
;==========================================
bits 32

  align 4
_main:
  mov   ax,0x10       ; Default data segment.
  mov   ds,ax
  mov   es,ax
  mov   ss,ax         ; We don't need a special stack segment, yet!
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

  ; TODO: What should I pass to the kernel here?
  jmp   8:0x100000    ; jumps to kernel.

.load_error:
  jmp   load_kernel_error

;-------------------
; Smaller routine used by protected mode C code.
;-------------------
struc calc_csum16_stk
.retaddr:   resd  1
.bufferptr: resd  1
.size:      resd  1
endstruc

global  calc_chksum16
; _u16 calc_checksum16(void *bufferptr, _u32 size);
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


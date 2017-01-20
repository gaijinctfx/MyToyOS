;======================================
; MyToyOS stage0 (partition MBR) boot.
; NASM source code
;======================================

struc dap
.size       resw  1
.sectors    resw  1
.bufferptr  resd  1   ; segment:offset pair.
.address    resq  1   ; LBA48 address
.length:
endstruc

bits 16
org 0
  ; Just to make sure we're in the correct segment.
  jmp 0x07c0:_start

;--------
;--------
signature:      db  'MyToyOS',0 ; 8 bytes!
drivenum:       db  0x80  ; Set by disk formating...
boot_start_sector:  dq  0 ; Boot partition LBA48 address. (same here!).
                          ;   4 KiB Stage1 Boot block and kernel blocks are here!
boot_blocks:        dd  0 ; Will be set below.

_start:
  cld
  mov   ax,cs
  mov   ds,ax
  mov   es,ax         ; we'll need es soon.

  ; Puts the stack at the end of lower RAM.
  cli
  mov   ax,0x9000
  mov   ss,ax
  mov   ax,0xfffc
  mov   sp,ax
  sti

  ; Show a small message warning we're booting...
  lea   si,[hello_msg]
  call  r_putstr

  ;...
  ; Read the stage1 and jump to it, unless we got an
  ; error, in this caso, show "System halted" and halts!
  ;...
  lea   si,[heap]
  mov   word [si+dap.size],dap.length
  mov   word [si+dap.sectors],8         ; read 8 sectors.
  mov   dword [si+dap.bufferptr],0x600
  mov   eax,[boot_start_sector]
  mov   edx,[boot_start_sector+4]
  push  eax
  push  edx
  mov   [si+dap.address],eax
  mov   [si+dap.address+4],edx
  mov   dl,[drivenum]
  mov   ah,0x42
  int   0x13        ; Read the sectors.
  pop   ebx
  pop   eax  
  jc    .read_error

  ; Jumps to stage1. DL has drive num, EBX:EAX has boot partition start sector,
  ; ECX has boot partition size, in blocks.  
  mov   ecx,[boot_blocks]
  jmp   0:0x600     ; Jump to stage1.

.read_error:
  lea   si,[stage1_read_error_msg]
  call  r_putstr

sys_halt:
  lea   si,[sys_halted_error_msg]
  call  r_putstr

.hlt_loop:
  hlt
  jmp   .hlt_loop    ; Just in case some IRQ/NMI wakes the cpu up!

;------------
; void r_putstr(char *s);
;
; Entry: DS:SI = s
; Destroys: AX, SI.
;
; OBS: Direction Flag must be cleared.
;-------------
r_putstr:
  lodsb
  test  al,al
  jz    .putstr_end
  mov   ah,0x0e
  int   0x10
  jmp   r_putstr
.putstr_end:
  ret

;-----------
; Strings
;-----------
hello_msg:
  db    "Stage0: Loading Stage1...",13,10,0
stage1_read_error_msg:
  db    "Error trying to read stage 1 sectors!",13,10,0
sys_halted_error_msg:
  db    "System Halted!",13,10,0

;-----------
; BIOS requires this signature.
;-----------
times 510-($-$$) db 0
boot_signature:
  db  0x55,0xaa

; Data area.
heap:

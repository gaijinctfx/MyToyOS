;======================================
; MyToyOS stage0 boot.
; NASM source code
;======================================

bits 16

org 0

  ; Makes sure we're in the correct segment.
  jmp 0x07c0:_start

;--------
; Drive geometry descriptor
;--------
drivenum:       db  0
start_lba:      dd  1   ; FIXME: Setup when disk is formated.
                        ;        Or, later, I can get it from
                        ;        the partition table.

_start:
  cld
  mov   ax,cs
  mov   ds,ax

  ; Puts the stack at the end of lower RAM.
  cli
  mov   ax,0x9000
  mov   ss,ax
  mov   ax,-4
  mov   sp,ax
  sti

  mov   si,boot_string
  call  putstr

  ;...
  ; Read the stage1 and jump to it, unless we got an
  ; error, in this caso, show "System halted" and halts!
  ;...
  mov   eax,[start_lba]
  mov   [dap_start],eax
  lea   si,[dap]
  mov   dl,[drivenum]

  mov   ah,0x42
  int   0x13        ; Read the sectors.
  jc    .read_error
  jmp   0x0060:0    ; Jump to stage1.

.read_error:
  mov   si,stage1_read_error
  call  putstr

sys_halt:
  mov   si,sys_halted_error
  call  putstr
.hlt_loop:
  hlt
  jmp   .hlt_loop    ; Just in case some IRQ/NMI wakes the cpu up!

;------------
; void putstr(char *s);
;
; Entry: DS:SI = s
;
; OBS: Direction Flag must be cleared.
;-------------
putstr:
  lodsb
  test  al,al
  jz    .putstr_end
  mov   ah,0x0e
  int   0x10
  jmp   putstr
.putstr_end:
  ret

;-----------
; Strings
;-----------
boot_string:
  db    "Stage0: Loading Stage1...",13,10,0
stage1_read_error:
  db    "Error trying to read stage 1 sectors!",13,10,0
sys_halted_error:
  db    "System Halted!",13,10,0

dap:
dap_size:     dw  dap_length-dap
dap_sectors:  dw  8
dap_buffer:   dd  0x600
dap_start:    dq  0
dap_length:

;-----------
; BIOS requires this signature.
;-----------
times 510-($-$$) db 0
boot_signature:
  db  0x55,0xaa

; Data area, if needed.
heap:

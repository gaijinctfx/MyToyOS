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
cylinder:       dw  0
head:           db  0
sector:         db  1 ; THIS sector.
stage1_sectors: db  8 ; arbitrary value!
                      ; 8 sectors will give us 4 KiB.
                      ; 360 KiB floppy disks have 9 sectors/cylinder!

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
  ; TODO:
  ; Read the stage1 and jump to it, unless we got an
  ; error, in this caso, show "System halted" and halts!
  ;...
  mov   ax,0x0060   ; Read 4 KiB to 0x0060:0000.
  mov   es,ax
  xor   bx,bx

  ; we'll read 4 KiB starting next sector.
  mov   cx,[cylinder] ; Cylinder and sector special BIOS
  xchg  ch,cl         ; encoding: CH = cyls lsb
  shr   cl,6          ;           CL = cc_ssssss
  mov   al,[sector]   ; where:
  inc   al            ;           cc = cyls 2 msb
  and   al,0x3f       ;           ssssss = sector.
  or    cl,al

  mov   al,[stage1_sectors]
  mov   dh,[head]
  mov   dl,[drivenum]

  mov   ah,2
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

;------------
; void chs_read_sectors(int c, char h, char s, char count);
;
; Entry:
;------------
chs_read_sectors:
  ret

boot_string:
  db    "Stage0: Loading Stage1...",13,10,0
stage1_read_error:
  db    "Error trying to read stage 1 sectors!",13,10,0
sys_halted_error:
  db    "System Halted!",13,10,0

times 510-($-$$) db 0
boot_signature:
  db  0x55,0xaa

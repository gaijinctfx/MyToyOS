;======================================
; MyToyOS stage0 (partition MBR) boot.
; NASM source code
;======================================

; Used by INT 0x13/AH=0x42 to read/write using LBA48.
struc disk_address_packet
.size       resw  1
.sectors    resw  1
.bufferptr  resd  1   ; segment:offset pair.
.address    resq  1   ; LBA48 address
.length:
endstruc

bits 16
org 0
  ; Just to make sure we're in the correct segment.
  ; Accordingly to BIOS Boot Specification 6.5.1 the current address is
  ;   0x0000:0x7C00. I want to make sure we are in segment 0 here!
  ; The same specification says ES:DI points to a PnP installation check structure (in all machines?),
  ;   and DL contains the drive number.
  jmp 0x07c0:_start

;--------
;--------
signature:          db  'MyToyOS',0 ; 8 bytes!
drivenum:           db  0x80        ; Obtained by BIOS data.
boot_start_sector:  dq  0           ; Boot partition LBA48 address.
                                    ;   4 KiB Stage1 Boot block and kernel blocks are here!
boot_blocks:        dd  0           ; Will be set later (maybe 1, maybe 2).

_start:
  mov   ax,cs
  mov   ds,ax
  mov   es,ax                       ; we'll need es soon.

  mov   [drivenum],dl               ; Save the drive number.

  ; Put the stack at the end of lower RAM (0x9fffc physical address).
  cli
  mov   ax,0x9000
  mov   ss,ax
  mov   ax,0xfffc
  mov   sp,ax
  sti

  ; Show a tiny message telling us we're booting...
  lea   si,[hello_msg]
  call  r_putstr

  ;...
  ; Read the stage1 and jump to it, unless we got an
  ; error, in this caso, show "System halted" and halts!
  ;...
  lea   si,[heap]
  mov   word  [si+disk_address_packet.size],disk_address_packet.length
  mov   word  [si+disk_address_packet.sectors],8         ; read 8 sectors (4 KiB block).
  mov   dword [si+disk_address_packet.bufferptr],0x600   ; logical address is 0x0000:0x0600.
  mov   eax,[boot_start_sector]                          ; EDX:EAX = LBA48.
  mov   edx,[boot_start_sector+4]
  push  edx                                              ; Save it on stack.
  push  eax
  mov   [si+disk_address_packet.address],eax             ; Set LBA48 on disk_address_packet structure.
  mov   [si+disk_address_packet.address+4],edx
  mov   dl,[drivenum]                                    ; recover drivenum expected by BIOS services.
  mov   ah,0x42                                          ; READ LONG SECTORS BIOS service.
  int   0x13        ; Read the sectors.
  jc    .read_error

  ; Jumps to stage1. DL has drive num, EBX:EAX has boot partition start sector,
  ; ECX has boot partition size, in blocks.  
  pop   eax                                              ; Recover LBA48 on EBX:EAX.
  pop   ebx  
  mov   ecx,[boot_blocks]                                ; Get # of boot blocks and pass to stage1.
  ; assuming DL is not changed by INT 0x13/AH=0x42.
  jmp   0:0x600                                          ; Jump to stage1.
                                                         ; Stage1 will load the kernel and run it.

.read_error:
  add   sp,8                                             ; Get rid of LBA48 saved on stack.

  ; Show disk read error.
  lea   si,[stage1_read_error_msg]
  call  r_putstr

sys_halt:
  ; Show system halted message.
  lea   si,[sys_halted_error_msg]
  call  r_putstr

.hlt_loop:
  hlt
  jmp   .hlt_loop                                         ; Just in case some IRQ/NMI wakes the cpu up!

;------------
; void r_putstr(char *s);
;
; Entry: DS:SI = s
; Destroys: AX, SI.
;
; OBS: Direction Flag must be cleared.
;-------------
r_putstr:
  cld
.loop:
  lodsb
  test  al,al
  jz    .putstr_end
  mov   ah,0x0e
  int   0x10
  jmp   .loop
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
; Partition table entries, if any:
;-----------
%ifdef HAS_PARITION_TABLE
times 0x1be-($-$$) db 0

; TODO: Define legacy partition table entry structure later.
part_entry_0: times 16 db 0
part_entry_1: times 16 db 0
part_entry_2: times 16 db 0
part_entry_3: times 16 db 0
%endif

;-----------
; BIOS requires this signature at the end of MBR.
;-----------
times 510-($-$$) db 0
boot_signature:
  db  0x55,0xaa

; Data area.
heap:

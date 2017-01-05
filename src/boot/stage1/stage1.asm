;=======================================
; stage 1 bootloader
;
; This stage have 2 blocks: One 16 bits and other 32.
; This stage will switch to protected mode.
;=======================================

; This is required since the GDT will map ALL memory from
; physical address 0 to 4 GiB - 1.
S1_OFFSET equ 0x600
%define S1_ADDR(x) ((x)+S1_OFFSET)

bits 16

org 0

_start:
  push  cs
  pop   ds

  ; OBS: At this point SS still points to 0x9000!

  ; TODO...

  cli

  ; Try to enable Gate A20.
  call  enable_gate_a20_int15h
  jnc   .gate_a20_enabled
  call  enable_gate_a20_kbdc
  jnc   .gate_a20_enabled
  call  enable_gate_a20_fast
.gate_a20_enabled:
  call  check_enabled_a20
  jc    error_enabling_gate_a20

  lgdt  [global_descriptors_table_struct]
  mov   eax,cr0
  or    ax,1                  ; Set PE bit.
  mov   cr0,eax
  jmp   8:S1_ADDR(go32)       ; Is this correct?!

error_enabling_gate_a20:
  mov   si,error_enabling_gate_a20_msg
  call  puts

sys_halt:
  hlt
  jmp   sys_halt

error_enabling_gate_a20_msg:
  db    "error enable Gate A20.",13,10,0

;------------------
; puts(char *s)
; Entry: SI=s
;------------------
puts:
  lodsb
  test  al,al
  jz    .puts_exit
  mov   ah,0x0e
  int   0x10
  jmp   puts
.puts_exit:
  ret

;===============================================
; Gate A20 routines
;===============================================
;-------------------
; Enable Gate A20 (Fast Gate A20 method)
;-------------------
enable_gate_a20_fast:
  cli
  in    al,0x92
  bts   ax,1
  jc    .enable_gate_a20_fast_exit
  and   al,0xfe
  out   0x92,al
.enable_gate_a20_fast_exit:
  sti
  ret

;--------------------
; Enable GateA20 (KBDC method)
;--------------------
enable_gate_a20_kbdc:
  cli
  
  call  .kbdc_wait1
  mov   al,0xad       ; Disable Keyboard.
  out   0x64,al
  call  .kbdc_wait1
  mov   al,0xd0       ; Read output port
  out   0x64,al
  call  .kbdc_wait2
  in    al,0x60
  mov   dl,al
  call  .kbdc_wait1
  mov   al,0xd1       ; Write output port
  out   0x64,al
  call  .kbdc_wait1
  mov   al,dl
  or    al,2          ; Set Gate A20 bit
  out   0x60,al
  call  .kbdc_wait1
  mov   al,0xae       ; Re-enable keyboard.
  out   0x64,al
  call  .kbdc_wait1

  sti
  ret

.kbdc_wait1:
  in    al,0x64
  test  al,2
  jnz   .kbdc_wait1
  ret
.kbdc_wait2:
  in    al,0x64
  test  al,1
  jz    .kbdc_wait2
  ret

;-------------------
; Enable Gate A20 (INT 0x15 method)
; Returns CF=0 if successful.
;-------------------
enable_gate_a20_int15h:
  mov   ax,0x2403     ; Query Gate A20 Support.
  int   0x15
  jc    .enabled_gate_a20_int15h_exit
  or    ah,ah
  jnz   .enabled_gate_a20_int15h_not_supported

  mov   ax,0x2402     ; Get GateA20 Status
  int   0x15
  jc    .enabled_gate_a20_int15h_exit
  or    ah,ah
  jnz   .enabled_gate_a20_int15h_not_supported

  mov   ax,0x2401     ; Enable Gate A20.
  int   0x15

.enabled_gate_a20_int15h_exit:
  ret

.enabled_gate_a20_int15h_not_supported:
  stc
  ret

;-------------------
; Checks if Gate A20 is enabled by writing the inverse of
; data located at 0xffff:0x510 on itself and comparing with
; data located at 0x0000:0x500.
;
; Returns CF=1 if A20 isn't enabled or CF=0 if it is!
;-------------------
check_enabled_a20:
  push  ds
  mov   si,0x500
  mov   di,0x510
  xor   ax,ax
  mov   ds,ax
  not   ax
  mov   es,ax

  lodsb
  mov   ah,[es:di]
  not   ah
  mov   [es:di],ah
  not   ah
  cmp   [si],al
  mov   [es:di],ah
  jne   .a20_enabled

  stc  
  pop   ds
  ret

.a20_enabled:
  clc
  pop   ds
  ret

;-------
; Global Descriptors Table
;
;     3                   2                   1  
;   1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
;  +---------------+-+-+-+-+-------+-+---+-+-------+---------------+
;  |               | |D| |A|  Seg  | | D | |       |               |
;  |  Base 31:24   |G|\|L|V| Limit |P| P |S|  Type |   Base 23:16  | +4
;  |               | |B| |L| 19:16 | | L | |       |               |
;  +---------------+-+-+-+-+-------+-+---+-+-------+---------------+
;  +-------------------------------+-------------------------------+
;  |                               |                               |
;  |         Base 15:0             |    Segment Limit 15:0         | +0
;  |                               |                               |
;  +-------------------------------+-------------------------------+
;-------
global_descriptors_table_struct:
  dw  global_descritors_table_end - global_descriptors_table - 1  ; Limit
  dd  S1_ADDR(global_descriptors_table)                           ; Address.

  align 8
global_descriptors_table:
  ; NULL descriptor
  dd  0,0

  ; Selector 0x08: CS DPL=0,32b,4 GiB Limit,Base=0
  dw  0xffff, 0
  db  0
  db  0x9a        ; Codeseg, execute/read, DPL=0
  db  0xcf        ; 4 GiB, 32 bits
  db  0

  ; Selector 0x10: DS DPL=0,32b,4 GiB limit,Base=0
  dw  0xffff, 0
  db  0
  db  0x92        ; Dataseg, read/write, DPL=0
  db  0xcf        ; 4 GiB, 32 bits
  db  0
global_descritors_table_end:

;===============================================
; All 32 bits protected mode routines goes below!
;===============================================

bits 32

; FIXME: Maybe is sufficient that the Stack is at the end
;        of usable lower RAM at this point...
STKTOP equ  0x9fffc

;===============================================
; Protected mode starts here.
;===============================================
  align 4
go32:
  ; We must jump here with IF disabled!!!
  ; Probably with NMI and all IRQ masked as well...
  mov   ax,0x10   ; Data selector
  mov   ds,ax
  mov   es,ax
  ;mov   fs,ax
  ;mov   gs,ax

  ; FIXME: Must choose an appropriate stack region!
  mov   ss,ax
  mov   esp,STKTOP

  ;TODO...
  ;...

  ; if everything is ok until now...
  jmp   8:0x100000    ; ...Jumps to kernel!

;===============================================
; Screen routines.
;===============================================

;-------
; Screen vars
;-------
current_x:  db  0
current_y:  db  0

;------
; Get current page address
; Returns EDI with base address.
; Destroys EAX and EDX.
;------
get_screen_page_base_addr:
  movzx edi,byte [0x462]    ; Current Video Page.
  mov   eax,4096
  inc   edi
  mul   edi
  add   eax,0xb8000
  mov   edi,eax
  ret

;-------
; Get current cursor position address.
; Destroys EAX, EDX, ESI, EDI and EBX.
;-------
get_current_cursor_position_addr:
  call  S1_ADDR(get_screen_page_base_addr)
  mov   esi,edi
  movzx ebx,byte [S1_ADDR(current_x)]
  movzx ecx,byte [S1_ADDR(current_y)]
  mov   eax,160
  mul   ecx
  mov   edi,eax
  shl   ebx,1
  add   edi,esi
  add   edi,ebx
  ret
  
;-------
; Advance cursor 1 char
;-------
advance_cursor:
  mov   ah,[S1_ADDR(current_x)]
  inc   ah
  cmp   ah,80
  jae   .next_line
.advance_cursor_exit:
  mov   [S1_ADDR(current_x)],ah
  ret
.next_line:
  xor   ah,ah
  mov   al,[S1_ADDR(current_y)]
  cmp   al,25
  jae   .scroll_up
  inc   al
  mov   [S1_ADDR(current_y)],al
  jmp   .advance_cursor_exit
.scroll_up:
  mov   [S1_ADDR(current_x)],ah
  call S1_ADDR(scroll_up)
  ret

;-------
; Scrolls page 1 line up:
;-------
scroll_up:
  call  S1_ADDR(get_screen_page_base_addr)
  mov   esi,edi
  add   esi,160
  mov   ecx,160*24
  rep   movsb
  mov   ax,0x0720
  mov   edi,esi
  mov   ecx,160
  rep   stosw
  ret

;-------
; Simple clear_screen
; Destroys: EDI, EDX, ECX and EAX.
;-------
clear_screen:
  ; DF is always zero?!
  call  S1_ADDR(get_screen_page_base_addr)
  mov   ecx,4000
  mov   ax,0x0720
  rep   stosw
  ret

;-------
; setup_current_pos (Gets the cursor current position from BIOS).
; Destroys EAX and EBX.
; Called only once!
;-------
_setup_current_pos:
  movzx ebx,byte [0x462]  ; Current Video Page.
  mov   ax,[0x450+ebx]    ; Current Page cursor position.
  mov   [S1_ADDR(current_x)],ah
  mov   [S1_ADDR(current_y)],al
  ret

;-------
; putchar
; Entry: AL = char.
;-------
putchar:
  mov   ecx,eax
  call  S1_ADDR(get_current_cursor_position_addr)
  mov   eax,ecx
  mov   ah,0x07
  stosw
  call  S1_ADDR(advance_cursor)
  ret

;===============================================
; Disk I/O routines.
;===============================================
; ... TODO ...
; The routines below will be called by 32 bits protected mode code.

;===============================================
; FileSystem Routines.
;===============================================


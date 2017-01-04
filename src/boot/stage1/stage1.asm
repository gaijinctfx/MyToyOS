;=======================================
; stage 1 bootloader
;
; This stage have 2 blocks: One 16 bits and other 32.
; This stage will switch to protected mode.
;=======================================

bits 16

org 0

_start:
  push  cs
  pop   ds

  ; OBS: At this point SS still points to 0x9000!

  hlt

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



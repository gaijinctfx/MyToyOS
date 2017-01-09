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

; this is @ 0:0x600
; Will enter here with:
;   DL = drivenum
;   EAX = start LBA28 partition sector.
;   ECX = number of partition sectors.
;   DS = ES = 0
_start:
  mov   [S1_ADDR(drivenum)],dl
  mov   [S1_ADDR(partition_start_lba28)],eax    ; FIXME: And LBA48?!
  mov   [S1_ADDR(partition_sectors)],ecx        ; FIXME: And LBA48?!

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
  in    al,0x92
  bts   ax,1
  jc    .enable_gate_a20_fast_exit
  and   al,0xfe
  out   0x92,al
.enable_gate_a20_fast_exit:
  ret

;--------------------
; Enable GateA20 (KBDC method)
;--------------------
enable_gate_a20_kbdc:
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
drivenum:               db  0x80
partition_start_lba28:  dd  0     ; FIXME: And LBA48?!
partition_sectors:      dd  0     ; FIXME: And LBA48?!

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
  dq  0

  ; Selector 0x08: CS DPL=0,32b,4 GiB Limit,Base=0
  dd  0x0000ffff  ; Codeseg, Base=0, execute/read, DPL=0, 4 GiB, 32 bits. 
  dd  0x00cf9a00

  ; Selector 0x10: DS DPL=0,32b,4 GiB limit,Base=0
  dd  0x0000ffff  ; Dataseg, Base=0, read/write, DPL=0, 4 GiB, 32 bits.
  dd  0x00cf9200 
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

  ; FIXME: Must choose an appropriate stack region!
  ;        For now i'll use 0x9fffc (end of lower RAM).
  mov   ss,ax
  mov   esp,STKTOP

  ;TODO...
  ; Loads kernel.
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
  call  get_screen_page_base_addr
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
  call  scroll_up
  ret

;-------
; Scrolls page 1 line up:
;-------
scroll_up:
  call  get_screen_page_base_addr
  mov   esi,edi
  add   esi,160
  mov   ecx,160*24
  cld
  rep   movsb
  mov   ax,0x0720
  mov   ecx,160
  rep   stosw
  ret

;-------
; Simple clear_screen
; Destroys: EDI, EDX, ECX and EAX.
;-------
clear_screen:
  ; DF is always zero?!
  call  get_screen_page_base_addr
  mov   ecx,4000
  mov   ax,0x0720
  cld
  rep   stosw
  ret

;-------
; setup_current_pos (Gets the cursor current position from BIOS).
; Destroys EAX and EBX.
; Called only once!
;-------
get_bios_current_screen_pos:
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
  call  get_current_cursor_position_addr
  mov   eax,ecx
  mov   ah,0x07
  stosw
  call  advance_cursor
  ret

; Entry: ESI = buffer ptr
;        ECX = buffer size
; Exit:  AX = 16 bit checksum
calc_chksum16:
  cld
  xor   ebx,ebx
.loop:
  lodsb
  xor   edx,edx
  mov   dx,ax
  add   bx,dx
  adc   bx,0
  dec   ecx
  jnz   .loop
  mov   ax,bx
  ret

;===============================================
; Disk I/O routines.
;===============================================
hdd_io_ports:
  dw  0x1f0, 0x1f0, 0x170, 0x170

; Gets controller info.
;   Entry:
;           AL = drive
;   Exit:
;           EDX:EAX = sectors count.
;           CL = maximum sectors per read.
;           CF=0, ok; CF=1, error
;           ZF=0, support LBA48; ZF=1, only LBA28
;
;   Destroys: EAX, EBX, ECX, EDX, ESI
;
get_hdd_info:
  movzx   ebx,al
  mov     bx,[S1_ADDR(hdd_io_ports)+ebx*2]
  and     al,1
  shl     al,4
  or      al,0x40       ; LBA bit set.
  lea     edx,[ebx+6]
  out     dx,al
  inc     edx
  mov     al,0xec       ; IDENTIFY_DEVICE command.
  out     dx,al

  ; Waits 400ns and waits for (!BSY | RDY)
  times 4 in al,dx
.wait_until_notbusy:
  in    al,dx
  mov   ch,al
  and   al,0xc0
  cmp   al,0x40
  jne   .wait_until_notbusy
  test  ch,1
  jnz   .error
  
  ; Read 1 sector to the heap.
  mov   edi,S1_ADDR(heap)
  push  edi
  push  edi
  mov   ecx,256
  cld
  rep   insw
  pop   esi

  ; Calculates checksum and compare it...
  mov   ecx,255*2
  call  calc_chksum16
  pop   edi
  cmp   word [edi+254],ax
  jnz   .error

  ; Is ATA device?
  test  byte [edi+2],0x80
  jnz   .error

  ; Supports LBA?
  test  byte  [edi+99],1
  jz    .error

  ; Supports LBA48?
  test  byte [edi+167],0x04   ; Supports LBA48? ZF=1 is NO.
  jz    .only_lba28

  mov   eax,[edi+200]
  mov   edx,[edi+202]
  jmp   .exit

.only_lba28:  
  ; if LBA28 supported, get maximum count
  movzx eax,word [edi+120]    ; sectors count.
  xor   edx,edx

.exit:
  mov   cl,[edi+94]     ; maximum sectors count per transaction.

  clc
  ret

.error:
  stc
  ret

; Entry (C calling convention):
;   int read_sectors(uint8_t drive,
;                    uint64_t lba,
;                    uint16_t sectors,
;                    void *bufferptr);
;
struc read_sectors_stk
.oldbp:     resd  1
.drive:     resd  1
.lba:       resq  1
.sectors:   resd  1
.bufferptr: resd  1
endstruc
;
; Exit: CF=1 (error), CF=0 (ok)
;
; Destroys ALL GPRs
;
; Note: Don't deal with specific errors here.
;
read_sectors:
  push  ebp

  mov   ebp,[esp+read_sectors_stk.drive]  
  mov   eax,[esp+read_sectors_stk.lba+4]  
  mov   esi,[esp+read_sectors_stk.lba]
  mov   ecx,[esp+read_sectors_stk.sectors]
  mov   edi,[esp+read_sectors_stk.bufferptr]  

  ; TODO: To check the maximum sectors transfer count!

  ; Check LBA
  test  eax,eax           ; TODO: LBA48 not yet implemented
  jnz   .error

  cmp   esi,0x0fffffff    ; Checks if can use LBA28...
  jbe   .read_lba28

.error:
  pop   ebp
  stc
  ret
  
.read_lba28:
  ; Get I/O port based on drive.
  mov   eax,ebp
  and   eax,3
  movzx ebx,word [S1_ADDR(hdd_io_ports)+eax*2]
  lea   edx,[ebx+2]

  ; Write Sectors Reg.
  mov   eax,ecx
  out   dx,al

  ; Write LBA Lo, Med & Hi Regs.
  inc   edx
  mov   eax,esi
  out   dx,al
  mov   eax,esi
  inc   edx
  shr   eax,8
  out   dx,al
  mov   eax,esi
  inc   edx
  shr   eax,16
  out   dx,al
  inc   edx
  shr   esi,24      ; Separate LBA[27:24]
  and   esi,0x0f
  mov   eax,ebp     ; Separate device bit.
  and   eax,1
  sal   eax,4       
  or    eax,esi     ; Write them.
  out   dx,al

  ; Write Command READ_SECTORS.
  inc   edx
  mov   al,0x20
  out   dx,al
  
  ; Waits 400ns and waits for (!BSY | RDY)
  times 4 in al,dx
.wait_until_notbusy:
  in    al,dx
  mov   ch,al
  and   al,0xc0
  cmp   al,0x40
  jne   .wait_until_notbusy

  ; Checks for errors.
  test  ch,1
  jnz   .error

  ; Read the sectors.
  movzx ecx,cl
  shl   ecx,8             ; Each sector has 256 words.
  lea   edx,[ebx]         ; Points to data port.
  cld                     ; Make sure transfers are forward.
  rep   insw

.read_lba_exit:
  pop   ebp
  clc
  ret

;===============================================
; FileSystem Routines.
;===============================================
; OBS: Each block has 4 KiB in size.
;      1st block is boot block (reserved).
;      2nd block is superblock.

; structures.
; FIXME: We'll use ext4fs?!
struc superblock
.inodes_count:          resd  1
.blocks_count_lo:       resd  1
.root_blocks_count_lo:  resd  1   ; blocks allocated by root.
.free_blocks_count_lo:  resd  1
.free_inodes_count:     resd  1
.first_data_block:      resd  1
.log_block_size:        resd  1   ; block_size is 2^(10+log_block_size)
.log_cluster_size:      resd  1   ; 2^(10+log_cluster_size) blocks if bigalloc enabled.
.blocks_per_group:      resd  1
.clusters_per_group:    resd  1   ; if bigalloc enabled.
.inodes_per_group:      resd  1
.mtime:                 resd  1   ; mount time.
.wtime:                 resd  1   ; write time.
.mnt_count:             resw  1   ; # of mounts since last fsck.
.max_mnt_count:         resw  1
.magic:                 resw  1
.state:                 resw  1
.errors:                resw  1
.minor_rev_level:       resw  1
.lastcheck:             resd  1
.checkinterval:         resd  1
.creator_os:            resd  1   ; which should I use?
.rev_level:             resd  1
.def_resuid:            resw  1
.def_resgid:            resw  1

.first_ino:             resd  1
.inode_size:            resw  1   ; in bytes.
.block_group_nr:        resw  1
.feature_compat:        resd  1
.feature_incompat:      resd  1
.feature_ro_compat:     resd  1
.uuid:                  resb  16  ; Volume UUID.
.volume_name:           resb  16  ; label.
.last_mounted_dir:      resb  64
.algo_usage_bitmap:     resd  1

.prealloc_blocks:       resb  1
.prealloc_dir_blocks:   resb  1
.reserved_gdt_blocks:   resw  1

.journal_data:          resb  128 ; don't care about journaling right now!

.blocks_count_hi:       resd  1
.root_blocks_count_hi:  resd  1
.free_blocks_count_hi:  resd  1
.min_extra_size:        resw  1
.want_extra_size:       resw  1
.flags:                 resd  1
.raid_stride:           resw  1
.mmp_interval:          resw  1
.mmp_block:             resq  1
.raid_stripe_width:     resd  1
.log_groups_per_flex:   resb  1
.checksum_type:         resb  1
.reserved1:             resw  1
.kbytes_writen:         resq  1
.snapshot_inum:         resd  1
.snapshot_id:           resd  1
.snapshot_root_blocks_count:  resq  1
.snapshot_list:         resd  1
.error_count:           resd  1
.first_error_time:      resd  1
.first_error_ino:       resd  1
.first_error_block:     resq  1
.first_error_func:      resb  32
.first_error_line:      resd  1
.last_error_time:       resd  1
.last_error_ino:        resd  1
.last_error_line:       resd  1
.last_error_block:      resq  1
.last_error_func:       resb  32
.mount_opts:            resb  64
.usr_quota_inum:        resd  1
.grp_quota_inum:        resd  1
.overhead_blocks:       resd  1
.backup_bgs:            resd  2
.encrypt_algos:         resb  4
.encrypt_pw_salt:       resb  16
.lpf_ino:               resd  1
.prj_quota_inum:        resd  1
.checksum_seed:         resd  1
.reserved2:             resd  98
.checksum:              resd  1     ; Superblock checksum.
endstruc

struc group_descriptor
.block_bitmap_lo:       resd  1
.inode_bitmap_lo:       resd  1
.inode_table_lo:        resd  1
.free_blocks_count_lo:  resw  1
.free_inodes_count_lo:  resw  1
.used_dirs_count_lo:    resw  1
.flags:                 resw  1
.exclude_bitmap_lo:     resd  1
.block_bitmap_csum_lo:  resw  1
.inode_bitmap_csum_lo:  resw  1
.itable_unused_lo:      resw  1
.checksum:              resw  1

.block_bitmap_hi:       resd  1
.inode_bitmap_hi:       resd  1
.inode_table_hi:        resd  1
.free_blocks_count_hi:  resw  1
.free_inodes_count_hi:  resw  1
.used_dirs_count_hi:    resw  1
.itable_unused_hi:      resw  1
.exclude_bitmap_hi:     resd  1
.block_bitmap_csum_hi:  resw  1
.inode_bitmap_csum_hi:  resw  1
.reserved:              resd  1
endstruc

struc inode
.mode:        resw  1
.uid:         resw  1
.size_lo:     resd  1
.atime:       resd  1
.ctime:       resd  1
.mtime:       resd  1
.dtime:       resd  1
.gid:         resw  1
.links_count: resw  1
.blocks_lo:   resd  1
.flags:       resd  1
.osd1:        resd  1
.block:       resb  60
.generation:  resd  1
.file_acl_lo: resd  1
.size_high:
.dir_acl:     resd  1
.obso_faddr:  resd  1
.osd2:        resb  12
.extra_size:  resw  1
.checksum_hi: resw  1
.ctime_extra: resd  1
.mtime_extra: resd  1
.atime_extra: resd  1
.crtime:      resd  1
.crtime_extra: resd  1
.version_hi:  resd  1
.projid:      resd  1
endstruc


; TODO: ...

;===============================================
; ELF format routines.
;===============================================
; TODO: ...

;===============================================
; DATA space (always at the end of binary).
;===============================================
  align 4
heap:

bits 32

section .bss

%define STK_TOP 16384
extern _end_bss

section .data

extern gdt_desc

section .text

extern _main32

_start:
  ; Stack will be at the end of bss plus 4 pages (4 pages stack size).
  mov   esp,_end_end + STK_TOP - 4
  call  setup_new_gdt
  lgdt  [gdt_desc]
  jmp   8:_main32

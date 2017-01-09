bits 16

; This section will begin at 0x60:0.
section .text16

global _start
extern main

_start:

; ...
; ...

  jmp   8:main    ; or, maybe, 8:(main+0x600).

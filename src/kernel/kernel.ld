/* Don't forget to use -m elf_i386 with ld! */
OUTPUT_FORMAT(binary)
SECTIONS
{
  /* 0:0x600 (real mode) or 8:0x600 (protected mode) is the starting point */
  . = 0x100000;
  .text : {
    _start = .;
    *(.text) 
  }
  .data : { *(.data) }
  .bss : { 
    _begin_bss = .;
    *(.bss) 
    _end_bss = .;
  }
}

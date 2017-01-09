OUTPUT_FORMAT(binary)
ENTRY(_start)
SECTIONS
{
  /* 0:0x600 (real mode) or 8:0x600 (protected mode) is the starting point */
  . = 0x600;
   .text : {
     _start = .;
     *(.text) 
   }
   .data : { *(.data) }
   _begin_bss = .;
   .bss : { *(.bss) }
   _end_bss = .;
}

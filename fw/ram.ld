MEMORY {
	ram (rwx)	: ORIGIN = 0x00000000, LENGTH = 8k
	}

/* Always be sure to change both - MEMORY and next variables */
__ram_start = 0x00000000;
__ram_length = 8k;

__stack     = __ram_start + __ram_length - 0x4;
_heap_end   = __stack - 0x1000;
PROVIDE (__stack =  __ram_start + __ram_length - 0x4);


SECTIONS
{
	.vectors :
	{
	 *(.vectors)
	} > ram

	.text :
	{
	 *(.text)
   *(.text.*)
	 . = ALIGN(0x4);
	} > ram
        
  .rodata :
  {
	 *(.rodata)
   *(.rodata.str1.1)
  } > ram

	. = ALIGN(0x4);
	__data_rom = .;
	PROVIDE(__data_rom = .);

	.breg :
	{
	 . = ALIGN(0x4);
	 __breg_start = .;
	 PROVIDE (__breg_start = .);
         *(.breg)
	 __breg_end = .;
	 PROVIDE (__breg_end = .);
	} > ram

	.uart :
	{
	 . = ALIGN(0x4);
	 __uart_mode = .;
	 PROVIDE (__uart_mode = .);
         *(.uart)
	} > ram

	.data : AT (__data_rom)
	{
	 . = ALIGN(0x4);
	 __data_start = .;
	 PROVIDE (__data_start = .);
	 *(.data)
   *(.data.*)
	 __data_end = .;
	 PROVIDE (__data_end = .);
	} > ram

	.bss :
	{
	 . = ALIGN(0x4);
	 __bss_start = .;
	 PROVIDE (__bss_start = .);
	 *(.bss)
	 __bss_end = .;
	 PROVIDE (__bss_end = .);
	} > ram

  . = ALIGN(0x4);
  PROVIDE (_heap_start = .);


	.stack :
	{
	 *(.stack)
	} > ram
}


MEMORY
{
    rom (rx)  : ORIGIN = 0x00000000, LENGTH = 0x01000000
    ram (rwx) : ORIGIN = 0x40000000, LENGTH = 0x08000000
}

STACK_SIZE = 0x8000;

SECTIONS
{
    .text :
    {
        KEEP(*(.vector*))
        *(.text*)
        *(.rodata*)
        _etext = .;
    } > rom

    .bss (NOLOAD) :
    {
        _sbss = .;
        *(.bss*)
        *(COMMON)
        _ebss = .;
    } > ram

    .data :
    {
        _sdata = .;
        *(.data*);
        _edata = .;
    } > ram AT > rom
    
    .stack (NOLOAD) :
    {
        . = ALIGN(8);
        . = . + STACK_SIZE;
        . = ALIGN(8);
    } > ram

    _end = .;
}
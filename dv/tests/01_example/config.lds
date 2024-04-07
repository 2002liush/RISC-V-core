OUTPUT_ARCH( "riscv" )

ENTRY( _start )

MEMORY
{
    itcm  : ORIGIN = 0x00000000, LENGTH = 16K
    dtcm  : ORIGIN = 0x00010000, LENGTH = 16K
}

SECTIONS
{
    .text.init          : { *(.text.init) } >itcm
    .text               : { *(.text) } >itcm

    .rodata             : { *(.rodata) } >dtcm
    .bss                : { *(.bss) } >dtcm
    .common             : { *(.common) *(.comm) } >dtcm
    .data               : { *(.data) } >dtcm
    .stack              : { *(.stack) } >dtcm
}

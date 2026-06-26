ENTRY(_start)
MEMORY { RAM (rwx) : ORIGIN = 0, LENGTH = 4K }
SECTIONS {
  .text   : { *(.text.init) *(.text*) } > RAM
  .rodata : { *(.rodata*) } > RAM
  .data   : { *(.data*) } > RAM
  .bss    : { __bss_start = .; *(.bss*) *(COMMON) __bss_end = .; } > RAM
  _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
//----------------------------------------------------------------------
// bigintadd.s
// Author: Alina Chen & Nickolas Casalinuovo
//----------------------------------------------------------------------

        .equ    TRUE, 1
        .equ    FALSE, 0
//----------------------------------------------------------------------

        .section .rodata

newLine:
    .string "\n"
promptStr:
    .string "%7ld %7ld %7ld\n"

//----------------------------------------------------------------------
        .section .data

lLineCount:
        .quad   0
lWordCount:
        .quad   0
lCharCount:
        .quad   0
iInWord:
        .word   FALSE

//----------------------------------------------------------------------
        .section .bss

iChar:
        .skip   4

//----------------------------------------------------------------------
        .section .text
//----------------------------------------------------------------------
// mywc.s
// Author: Alina Chen & Nickolas Casalinuovo
//----------------------------------------------------------------------

        .equ    TRUE, 1
        .equ    FALSE, 0
//----------------------------------------------------------------------

        .section .rodata

newLine:
    .string '\n'

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

        //--------------------------------------------------------------
        //  Write to stdout counts of how many lines, words, and
        //  characters are in stdin. A word is a sequence of
        //  non-whitespace characters. Whitespace is defined by the
        //  isspace() function. Return 0.
        //--------------------------------------------------------------

        // Must be a multiple of 16
        .equ    MAIN_STACK_BYTECOUNT, 16
        .global main

main:
    // Prolog
    sub     sp, sp, MAIN_STACK_BYTECOUNT
    str     x30, [sp]
inputLoop:
    // if((iChar = getchar()) == EOF) goto endInputLoop //
    bl      getchar  // w0 stores the value of getchar
    adr     x1, iChar
    str     w0, [x1] // iChar = getchar()
    cmp     w0, -1 // iChar == -1
    beq     endInputLoop

    // lCharCount++
    adr     x0, lCharCount
    ldr     x1, [x0]
    add     x1, x1, 1
    str     x1, [x0]

    // if (!isspace(iChar)) goto else1; // if 1
    adr     x0, iChar
    ldr     x0, [x0]
    bl      isspace
    cmp     w0, FALSE
    beq     else1

    // if (!iInWord) goto endif1; // if 2
    adr     x0, iInWord
    ldr     x0, [x0]
    cmp     x0, FALSE
    beq     endif1

    // lWordCount++;
    adr     x0, lWordCount
    ldr     x1, [x0]
    add     x1, x1, 1
    str     x1, [x0]

    // iInWord = FALSE;
    adr     x0, iInWord
    mov     w1, FALSE
    str     w1, [x0]

    // goto endif1;
    b       endif1
else1:
    // if (iInWord) goto endif1;
    adr     x0, iInWord
    ldr     x0, [x0]
    cmp     x0, TRUE
    beq     endif1

    // iInWord = TRUE;
    adr     x0, iInWord
    mov     w1, TRUE
    str     w1, [x0]

    // goto endif1;
    b       endif1
endif1:
    // if (iChar != '\n') goto inputLoop;
    adr     x0, iChar
    ldr     w0, [x0]
    mov     w1, newLine
    cmp     w0, w1
    bne     endInputLoop

    // lLineCount++;
    adr     x0, lLineCount
    ldr     x1, [x0]
    add     x1, x1, 1
    str     x1, [x0]

    // goto inputLoop;
    b       inputLoop
endInputLoop:
    // if (!iInWord) goto endif;
    adr     x0, iInWord
    ldr     w0, [x0]
    cmp     w0, FALSE
    beq     endif

    // lWordCount++;
    adr     x0, lWordCount
    ldr     x1, [x0]
    add     x1, x1, 1
    str     x1, [x0]

endif:
    // printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
    adr     x0, promptStr
    adr     x1, lLineCount
    adr     x2, lWordCount
    adr     x3, lCharCount
    bl      printf

    // Epilog and return 0
    mov     w0, 0
    ldr     x30, [sp]
    add     sp, sp, MAIN_STACK_BYTECOUNT
    // return 0;
    ret
    .size   main, (. - main)

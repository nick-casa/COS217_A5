//----------------------------------------------------------------------
// mywc.s
// Author: Alina Chen & Nickolas Casalinuovo
//----------------------------------------------------------------------

        .equ    TRUE, 1
        .equ    FALSE, 0

//----------------------------------------------------------------------
        .section .data

lLineCount:
        .quad   0
lWordCount:
        .quad   0
lCharCount:
        .quad   0
iInWord:
        .byte   FALSE

//----------------------------------------------------------------------
        .section .bss

iChar:
        .skip   8

//----------------------------------------------------------------------
        .section .text

        //--------------------------------------------------------------
        //  Write to stdout counts of how many lines, words, and
        //  characters are in stdin. A word is a sequence of
        //  non-whitespace characters. Whitespace is defined by the
        //  isspace() function. Return 0.

        // Must be a multiple of 16
        .equ    MAIN_STACK_BYTECOUNT, 16
        .global main

main:
    // Prolog
    sub     sp, sp, MAIN_STACK_BYTECOUNT
    str     x30, [sp]
inputLoop:
    // if((iChar = getchar()) == EOF) goto endInputLoop //
    bl      getchar
    adr     x1, iChar
    cmp
    beq     endInputLoop

    // lCharCount++;
    // if (!isspace(iChar)) goto else1; // if 1
    // if (!iInWord) goto endif1; // if 2
    // lWordCount++;
    // iInWord = FALSE;
    // goto endif1;
else1:
    // if (iInWord) goto endif1;
    // iInWord = TRUE;
    // goto endif1;
endif1:
    // if (iChar != '\n') goto inputLoop;
    // lLineCount++;
    // goto inputLoop;
endInputLoop:
    // if (!iInWord) goto endif;
    // lWordCount++;
endif:
    // printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
    // return 0;

    // Epilog and return 0
    mov     w0, 0
    ldr     x30, [sp]
    add     sp, sp, MAIN_STACK_BYTECOUNT
    ret
    .size   main, (. - main)

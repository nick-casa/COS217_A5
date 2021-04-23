//----------------------------------------------------------------------
// bigintadd.s
// Author: Alina Chen & Nickolas Casalinuovo
//----------------------------------------------------------------------

        .equ    TRUE, 1
        .equ    FALSE, 0
//----------------------------------------------------------------------

        .section .rodata

//----------------------------------------------------------------------
        .section .data


//----------------------------------------------------------------------
        .section .bss


//----------------------------------------------------------------------
        .section .text

        // Must be a multiple of 16
        .equ    LARGER_STACK_BYTECOUNT, 32

        // Local variable stack offsets:
        .equ    LLARGER, 8

        // Parameter stack offsets:
        .equ    LLENGTH2,   16
        .equ    LLENGTH1,    24

BigInt_larger:
    // Prolog
    sub     sp, sp, LARGER_STACK_BYTECOUNT
    // long lLarger
    str     x30, [sp]
    str     x0, [sp, LLENGTH1]
    str     x1, [sp, LLENGTH2]


    // if (lLength1 <= lLength2) goto else1;
    ldr     x0, [sp, LLENGTH1]
    ldr     x1, [sp, LLENGTH2]
    cmp     x0, x1
    ble     else1

    // lLarger = lLength1;
    str     x0, [sp, LLARGER]

    // goto endif1;
    bl      endif1

else1:
    // lLarger = lLength2;
    str     x1, [sp, LLARGER]

endif1:
     // Epilog and return LLARGER
     ldr     x0, [sp, LLARGER]
     ldr     x30, [sp]
     add     sp, sp, LARGER_STACK_BYTECOUNT
     ret

     .size   BigInt_larger, (. - BigInt_larger)


//--------------------------------------------------------------------//

// Assign the sum of oAddend1 and oAddend2 to oSum.  oSum should be
// distinct from oAddend1 and oAddend2.  Return 0 (FALSE) if an
// overflow occurred, and 1 (TRUE) otherwise.

// Must be a multiple of 16
        .equ    ADD_STACK_BYTECOUNT, 64

        // Local variables stack offsets:
        .equ    LSUMLENGTH, 8
        .equ    LINDEX, 16
        .equ    ULSUM, 24
        .equ    ULCARRY, 32

        // Parameter stack offsets:
        .equ    OSUM, 40
        .equ    OADDEND2, 48
        .equ    OADDEND1, 56

        .equ    MAX_DIGITS, 32768
        .equ    SIZE_UNSIGNEDLONG, 8
        .global BigInt_add

BigInt_add:
 // Prolog
    sub     sp, sp, ADD_STACK_BYTECOUNT
    str     x30, [sp]
    str     x0, [sp, OADDEND1]
    str     x1, [sp, OADDEND2]
    str     x3, [sp, OSUM]

    // unsigned long ulCarry;
    // unsigned long ulSum;
    // long lIndex;
    // long lSumLength;

    // Determine the larger length.
    // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
    ldr     x0, [sp, OADDEND1]
    ldr     x0, [x0]
    ldr     x1, [sp, OADDEND2]
    ldr     x1, [x1]
    bl      BigInt_larger
    str     x0, [sp, LSUMLENGTH]

    // Clear oSum's array if necessary.
    // if (oSum->lLength <= lSumLength) goto endif2;
    ldr     x0, [sp, OSUM]
    ldr     x0, [x0]
    ldr     x1, [sp, LSUMLENGTH]
    cmp     x0, x1
    ble     endif2

    // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
    // CHECK HERE
    ldr     x0, [sp, OSUM]
    add     x0, x0, 8
    ldr     x0, [x0]
    //////////////////
    mov     x1, 0
    mov     x2, MAX_DIGITS
    mov     x3, SIZEOF_UNSIGNEDLONG
    mul     x2, x2, x3
    bl      memset

endif2:
    // Perform the addition.
    // ulCarry = 0;
    mov     x0, 0
    str     x0, [sp, ULCARRY]
    // lIndex = 0;
    str     x0, [sp, LINDEX]

loop1:
    // if(lIndex >= lSumLength) goto endLoop;
    ldr     x0, [sp, LINDEX]
    ldr     x1, [sp, LSUMLENGTH]
    cmp     x0, x1
    bge     endLoop

    // ulSum = ulCarry;
    ldr     x0, [sp, ULCARRY]
    str     x0, [sp, ULSUM]

    // ulCarry = 0;
    mov     x0, 0
    str     x0, [sp, ULCARRY]

    // ulSum += oAddend1->aulDigits[lIndex]
    ldr     x0, [sp, ULSUM]
    ldr     x1, [sp, OADDEND1]
    add     x1, x1, 8            // gets to aulDigits
    ldr     x2, [sp, LINDEX]     // loads lIndex into x2
    ldr     x1, [x1, x2, lsl 3]
    add     x0, x0, x1
    str     x0, [sp, ULSUM]

    // if (ulSum >= oAddend1->aulDigits[lIndex])  goto endif3;
    cmp     x0, x1
    bhs     endif3

    // ulCarry = 1;
    mov     x0, 1
    str     x0, [sp, ULCARRY]

endif3:
    // ulSum += oAddend2->aulDigits[lIndex];
    ldr     x0, [sp, ULSUM]
    ldr     x1, [sp, OADDEND2]
    add     x1, x1, 8            // gets to aulDigits
    ldr     x2, [sp, LINDEX]     // loads lIndex into x2
    ldr     x1, [x1, x2, lsl 3]
    add     x0, x0, x1
    str     x0, [sp, ULSUM]

    // if (ulSum >= oAddend2->aulDigits[lIndex]) goto endif4; /* Check for overflow. */
    cmp     x0, x1
    bhs     endif4

    // ulCarry = 1;
    mov     x0, 1
    str     x0, [sp, ULCARRY]

endif4:
    // oSum->aulDigits[lIndex] = ulSum;
    //check this
    ldr     x0, [sp, ULSUM]
    ldr     x1, [sp, OSUM]
    add     x1, x1, 8
    ldr     x2, [sp, LINDEX]
    str     x0, [x1, x2, lsl 3]

    // lIndex++;
    ldr     x0, [sp, LINDEX]
    add     x0, x0, 1
    str     x0, [sp, LINDEX]

    // goto loop1;
    bl loop1

endLoop:
    // Check for a carry out of the last "column" of the addition.
    // if (ulCarry != 1) goto endif5;
    ldr     x0, [sp, ULCARRY]
    cmp     x0, 1
    bne     endif5

    // if (lSumLength != MAX_DIGITS) goto endif6;
    ldr     x0, [sp, LSUMLENGTH]
    cmp     x0, MAX_DIGITS
    bne     endif6

    // return FALSE;
    mov     x0, FALSE
    ret     x0

endif6:
    // oSum->aulDigits[lSumLength] = 1;
    //check this
    mov     x0, 1
    ldr     x1, [sp, OSUM]
    add     x1, x1, 8
    ldr     x2, [sp, LSUMLENGTH]
    str     x0, [x1, x2, lsl 3]

    // lSumLength++;
    ldr     x0, [sp, LSUMLENGTH]
    add     x0, x0, 1
    str     x0, [sp, LSUMLENGTH]

endif5:
    // Set the length of the sum.
    // oSum->lLength = lSumLength;
    ldr     x0, [sp, OSUM]
    ldr     x0, [x0]
    ldr     x1, [sp, LSUMLENGTH]
    str     x1, [x0]

    // return TRUE;
    mov     w0, 0
    ldr     x30, [sp]
    add     sp, sp, ADD_STACK_BYTECOUNT
    mov     x1, 1
    ret     x1
    .size   BigInt_add, (. - BigInt_add)

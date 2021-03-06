//----------------------------------------------------------------------
// bigintaddopt.s
// Author: Alina Chen & Nickolas Casalinuovo
//----------------------------------------------------------------------
        .equ    TRUE, 1
        .equ    FALSE, 0
//----------------------------------------------------------------------
        .section .text

        // Must be a multiple of 16
        .equ    LARGER_STACK_BYTECOUNT, 32

        // Local variable stack offsets:
        LLARGER     .req x21 //callee-saved

        // Parameter stack offsets:
        LLENGTH2    .req x20 //callee-saved
        LLENGTH1    .req x19

BigInt_larger:
    // Prolog
    sub     sp, sp, LARGER_STACK_BYTECOUNT
    str     x30, [sp]
    str     x19, [sp, 8]
    str     x20, [sp, 16]
    str     x21, [sp, 24]

    // store parameters in registers
    mov     LLENGTH1, x0
    mov     LLENGTH2, x1

    // long lLarger

    // if (lLength1 <= lLength2) goto else1;
    cmp     x0, x1
    ble     else1

    // lLarger = lLength1;
    mov     LLARGER, LLENGTH1

    // goto endif1;
    b      endif1

else1:
    // lLarger = lLength2;
    mov     LLARGER, LLENGTH2

endif1:
     // Epilog and return LLARGER
     mov     x0, LLARGER
     ldr     x30, [sp]
     ldr     x19, [sp, 8]
     ldr     x20, [sp, 16]
     ldr     x21, [sp, 24]
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
        LSUMLENGTH  .req x25
        LINDEX      .req x24
        ULSUM       .req x23
        ULCARRY     .req x22

        // Parameter stack offsets:
        OSUM        .req x21
        OADDEND2    .req x20 //callee-saved
        OADDEND1    .req x19

        .equ    MAX_DIGITS, 32768
        .equ    SIZE_UNSIGNEDLONG, 8

        .global BigInt_add

BigInt_add:
    // Prolog
    sub     sp, sp, ADD_STACK_BYTECOUNT
    str     x30, [sp]
    str     x19, [sp, 8]
    str     x20, [sp, 16]
    str     x21, [sp, 24]
    str     x22, [sp, 32]
    str     x23, [sp, 40]
    str     x24, [sp, 48]
    str     x25, [sp, 56]

    // store parameters in registers
    mov     OADDEND1, x0
    mov     OADDEND2, x1
    mov     OSUM, x2

    // unsigned long ulCarry;
    // unsigned long ulSum;
    // long lIndex;
    // long lSumLength;

    // Determine the larger length.
    // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
    ldr     x0, [x0]
    ldr     x1, [x1]
    bl       BigInt_larger
    mov     LSUMLENGTH, x0

    // Clear oSum's array if necessary.
    // if (oSum->lLength <= lSumLength) goto endif2;
    ldr     x2, [OSUM]
    cmp     x2, LSUMLENGTH
    ble     endif2

    //  memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
    add     x0, OSUM, 8
    mov     x1, 0
    mov     x2, MAX_DIGITS
    mov     x3, SIZE_UNSIGNEDLONG
    mul     x2, x2, x3
    bl      memset

endif2:
    // Perform the addition.
    // ulCarry = 0;
    mov     ULCARRY, 0
    mov     LINDEX, 0

loop1:
    // if(lIndex >= lSumLength) goto endLoop;
    cmp     LINDEX, LSUMLENGTH
    bge     endLoop

    // ulSum = ulCarry;
    mov     ULSUM, ULCARRY


    // ulCarry = 0;
    mov     ULCARRY, 0

    // ulSum += oAddend1->aulDigits[lIndex]
    add     x1, OADDEND1, 8            // gets to aulDigits
    ldr     x1, [x1, LINDEX, lsl 3]
    add     ULSUM, ULSUM, x1

    // if (ulSum >= oAddend1->aulDigits[lIndex])  goto endif3;
    cmp     ULSUM, x1
    bhs     endif3

    // ulCarry = 1;
    mov     ULCARRY, 1

endif3:
    //  ulSum += oAddend2->aulDigits[lIndex];
    add     x1, OADDEND2, 8    //  gets to aulDigits
    ldr     x1, [x1, LINDEX, lsl 3]
    add     ULSUM, ULSUM, x1

    // if (ulSum >= oAddend2->aulDigits[lIndex]) goto endif4; /* Check for overflow. */
    cmp     ULSUM, x1
    bhs     endif4

    // ulCarry = 1;
    mov     ULCARRY, 1

endif4:
    // oSum->aulDigits[lIndex] = ulSum;
    mov     x0, ULSUM
    add     x1, OSUM, 8
    str     x0, [x1, LINDEX, lsl 3]

    // lIndex++;
    add     LINDEX, LINDEX, 1

    // goto loop1;
    b       loop1

endLoop:
    // Check for a carry out of the last "column" of the addition.
    // if (ulCarry != 1) goto endif5;
    cmp     ULCARRY, 1
    bne     endif5

    // if (lSumLength != MAX_DIGITS) goto endif6;
    cmp     LSUMLENGTH, MAX_DIGITS
    bne     endif6

    // return FALSE;
    mov     x0, FALSE
    ldr     x30, [sp]
    ldr     x19, [sp, 8]
    ldr     x20, [sp, 16]
    ldr     x21, [sp, 24]
    ldr     x22, [sp, 32]
    ldr     x23, [sp, 40]
    ldr     x24, [sp, 48]
    ldr     x25, [sp, 56]
    add     sp, sp, ADD_STACK_BYTECOUNT
    ret

endif6:
    // oSum->aulDigits[lSumLength] = 1;
    mov     x0, 1
    add     x1, OSUM, 8
    mov     x2, LSUMLENGTH
    str     x0, [x1, x2, lsl 3]


    // lSumLength++;
    add     LSUMLENGTH,LSUMLENGTH,1

endif5:
    // oSum->lLength = lSumLength;
    str     LSUMLENGTH, [OSUM]

    // return TRUE;
    mov     x0, TRUE
    ldr     x30, [sp]
    ldr     x19, [sp, 8]
    ldr     x20, [sp, 16]
    ldr     x21, [sp, 24]
    ldr     x22, [sp, 32]
    ldr     x23, [sp, 40]
    ldr     x24, [sp, 48]
    ldr     x25, [sp, 56]
    add     sp, sp, ADD_STACK_BYTECOUNT
    ret
    .size   BigInt_add, (. - BigInt_add)

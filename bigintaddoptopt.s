//----------------------------------------------------------------------
// bigintaddopt.s
// Author: Alina Chen & Nickolas Casalinuovo
//----------------------------------------------------------------------
        .equ    TRUE, 1
        .equ    FALSE, 0
//----------------------------------------------------------------------
        .section .text

        // Assign the sum of oAddend1 and oAddend2 to oSum.  oSum should be
        // distinct from oAddend1 and oAddend2.  Return 0 (FALSE) if an
        // overflow occurred, and 1 (TRUE) otherwise.
        // Must be a multiple of 16
        .equ    ADD_STACK_BYTECOUNT, 48

        // Local variables registers:
        LSUMLENGTH  .req x24 // callee-saved
        LINDEX      .req x23 // callee-saved
        ULSUM       .req x22 // callee-saved

        // Parameter registers
        OSUM        .req x21 // callee-saved
        OADDEND2    .req x20 // callee-saved
        OADDEND1    .req x19 // callee-saved

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

    // store parameters in registers
    mov     OADDEND1, x0
    mov     OADDEND2, x1
    mov     OSUM, x2
        
    // if (oAddend1->lLength <= oAddend2->lLength) goto else1;
    ldr     x0, [x0]
    ldr     x1, [x1]
    cmp     x0, x1
    ble     else1

    // lSumLength = oAddend1->lLength;
    mov     LSUMLENGTH, x0

    // goto endif1;
    b       endif1

else1:
    // lSumLength = oAddend2->lLength
    mov     LSUMLENGTH, x1

endif1:
    // Determine the larger length.
    // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
    // if (oSum->lLength <= lSumLength) goto endif2;
    add     x0, OSUM, 8
    ldr     x2, [OSUM]
    cmp     x2, LSUMLENGTH
    ble     endif2

    //  memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
    mov     x1, 0
    mov     x2, MAX_DIGITS
    mov     x3, SIZE_UNSIGNEDLONG
    mul     x2, x2, x3
    bl      memset

endif2:
    // Perform the addition.
    // lIndex = 0    
    mov     LINDEX, 0
    // ulSum = 0    
    mov     ULSUM, 0
    add x5, OADDEND1, 8  // x5 has oAddend1->aulDigits
    add x6, OADDEND2, 8  // x6 has oAddend1->aulDigits

    // if(lIndex >= lSumLength) goto endLoop;
    cmp     LINDEX, LSUMLENGTH
    bge     endLoop

loop:
    // set carry flag to 0
    adcs    x0, x0, xzr

    // ulSum += oAddend1->aulDigits[lIndex]
    ldr     x7, [x5, LINDEX, lsl 3]
    adcs    ULSUM, ULSUM, x7

    //  ulSum += oAddend2->aulDigits[lIndex];
    ldr     x9, [x6, LINDEX, lsl 3]
    bcc     addCarryNotSet
    add     ULSUM, ULSUM, x9
    b       postAdd

addCarryNotSet:
    adcs    ULSUM, ULSUM, x9

postAdd:
    // oSum->aulDigits[lIndex] = ulSum;
    str     ULSUM, [x0, LINDEX, lsl 3]

    // lIndex++;
    add     LINDEX, LINDEX, 1

    bcc     carry0;
carry1: // ULSUM = 1 if carry flag is 1
    mov     ULSUM, 1
    b       endBranch
carry0: // ULSUM = 0 if carry flag is 0
    mov     ULSUM, 0

endBranch:
    // if(lIndex < lSumLength) goto loop1;
    cmp     LINDEX, LSUMLENGTH
    blt     loop

endLoop:
    // Check for a carry out of the last "column" of the addition.
    // if (ulCarry != 1) goto endif5;
    cmp      ULSUM, 1
    bne      endif5

    // if (lSumLength != MAX_DIGITS) goto endif6;
    cmp     LSUMLENGTH, MAX_DIGITS
    bne     endif6
    // return FALSE;
    mov     x0, FALSE
    b       return

endif6:
    // oSum->aulDigits[lSumLength] = 1;
    mov     x4, 1
    str     x4, [x0, LSUMLENGTH, lsl 3]
    // lSumLength++;
    add     LSUMLENGTH,LSUMLENGTH,1

endif5:
    // oSum->lLength = lSumLength;
    str     LSUMLENGTH, [OSUM]
    // return TRUE;
    mov     x0, TRUE

return:
    ldr     x30, [sp]
    ldr     x19, [sp, 8]
    ldr     x20, [sp, 16]
    ldr     x21, [sp, 24]
    ldr     x22, [sp, 32]
    ldr     x23, [sp, 40]
    ldr     x24, [sp, 48]
    add     sp, sp, ADD_STACK_BYTECOUNT
    ret
    .size   BigInt_add, (. - BigInt_add)

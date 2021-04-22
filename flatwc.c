/*--------------------------------------------------------------------*/
/* mywc.c                                                             */
/* Author: Bob Dondero                                                */
/*--------------------------------------------------------------------*/

#include <stdio.h>
#include <ctype.h>

/*--------------------------------------------------------------------*/

/* In lieu of a boolean data type. */
enum {FALSE, TRUE};

/*--------------------------------------------------------------------*/

static long lLineCount = 0;      /* Bad style. */
static long lWordCount = 0;      /* Bad style. */
static long lCharCount = 0;      /* Bad style. */
static int iChar;                /* Bad style. */
static int iInWord = FALSE;      /* Bad style. */

/*--------------------------------------------------------------------*/

/* Write to stdout counts of how many lines, words, and characters
   are in stdin. A word is a sequence of non-whitespace characters.
   Whitespace is defined by the isspace() function. Return 0. */

int main(void)
{

    inputLoop:
        if((iChar = getchar()) == EOF) goto endInputLoop;
        lCharCount++;
            if (!isspace(iChar)) goto else1; // if 1
                if (!iInWord) goto endif1; // if 2
                lWordCount++;
                iInWord = FALSE;
                goto endif1;
            else1:
                if (iInWord) goto endif1;
                iInWord = TRUE;
                goto endif1;
            endif1:
                if (iChar != '\n') goto inputLoop;
                lLineCount++;
        goto inputLoop;
    endInputLoop:
        if (!iInWord) goto endif;
        lWordCount++;
    endif:
        printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
        return 0;
}

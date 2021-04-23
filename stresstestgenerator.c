/************************************************************/
/* stresstestgenerator.c                                    */
/* Created by Alina Chen & Nickolas Casalinuovo on 4/23/21. */
/************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <time.h>

enum {CHAR_COUNT = 50000};
int main(void){
    unsigned int random;
    int i;
    int count = 0;
    srand(rand());
    for (i = 0; i < CHAR_COUNT; i++ ) {
        random = rand();
        random %= 0x7F;
        /* 0x09, 0x0A, and 0x20 through 0x7E */
        if (random == 0x09 || random == 0x0A || (random > 0x20 && random < 0x7E)) {
            if (random == 0x0A) count++;
            if (count <= 1000) fprintf(stdout, "%c", random);
        }
    }
    return 0;
}
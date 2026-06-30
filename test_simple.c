#include <stdio.h>
#include "libcheckisomd5.h"

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <iso>\n", argv[0]);
        return 1;
    }
    
    int rc = mediaCheckFile(argv[1], NULL, NULL);
    printf("Result: %d (0=FAIL, 1=PASS)\n", rc);
    return rc != 1;
}

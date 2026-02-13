#include <stdio.h>
#include <stdlib.h>
#include "libcheckisomd5.h"

int main() {
    const char *iso = "/tmp/test.iso";
    
    printf("Testing ISO: %s\n", iso);
    
    // Print the embedded checksum
    int rc = printMD5SUM(iso);
    printf("printMD5SUM returned: %d\n\n", rc);
    
    // Check the ISO
    printf("Verifying checksum...\n");
    rc = mediaCheckFile(iso, NULL, NULL);
    printf("mediaCheckFile returned: %d\n", rc);
    
    switch(rc) {
        case 0: printf("Result: PASS\n"); break;
        case 1: printf("Result: FAIL\n"); break;
        case 2: printf("Result: NOT FOUND\n"); break;
        default: printf("Result: UNKNOWN (%d)\n", rc); break;
    }
    
    return rc;
}

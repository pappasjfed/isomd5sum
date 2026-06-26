#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "libcheckisomd5.h"
#include "utilities.h"

int main() {
    const char *iso = "/tmp/test3.iso";
    
    printf("Testing ISO: %s\n\n", iso);
    
    // Print the embedded checksum
    int rc = printMD5SUM(iso);
    
    // Check the ISO without callback
    printf("\nVerifying checksum without callback...\n");
    rc = mediaCheckFile(iso, NULL, NULL);
    printf("mediaCheckFile returned: %d\n", rc);
    
    const char *result_str;
    switch(rc) {
        case 0: result_str = "PASS (ISOMD5SUM_CHECK_PASSED)"; break;
        case 1: result_str = "FAIL (ISOMD5SUM_CHECK_FAILED)"; break;
        case 2: result_str = "ABORTED (ISOMD5SUM_CHECK_ABORTED)"; break;
        case 3: result_str = "NOT FOUND (ISOMD5SUM_CHECK_NOT_FOUND)"; break;
        case 4: result_str = "FILE NOT FOUND (ISOMD5SUM_FILE_NOT_FOUND)"; break;
        default: result_str = "UNKNOWN"; break;
    }
    printf("Result: %s\n", result_str);
    
    return rc;
}

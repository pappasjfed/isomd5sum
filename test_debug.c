#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "libcheckisomd5.h"
#include "utilities.h"

int progress_cb(void *data, long long offset, long long total) {
    static long long last_offset = -1;
    if (offset != last_offset) {
        printf("Progress: %lld / %lld (%.1f%%)\n", offset, total, 100.0 * offset / total);
        last_offset = offset;
    }
    return 0;
}

int main() {
    const char *iso = "/tmp/test.iso";
    
    printf("Testing ISO: %s\n", iso);
    
    // Check the ISO with callback
    printf("\nVerifying checksum with callback...\n");
    int rc = mediaCheckFile(iso, progress_cb, NULL);
    printf("\nmediaCheckFile returned: %d\n", rc);
    
    const char *result_str;
    switch(rc) {
        case 0: result_str = "ISOMD5SUM_CHECK_PASSED"; break;
        case 1: result_str = "ISOMD5SUM_CHECK_FAILED"; break;
        case 2: result_str = "ISOMD5SUM_CHECK_ABORTED"; break;
        case 3: result_str = "ISOMD5SUM_CHECK_NOT_FOUND"; break;
        case 4: result_str = "ISOMD5SUM_FILE_NOT_FOUND"; break;
        default: result_str = "UNKNOWN"; break;
    }
    printf("Result: %s\n", result_str);
    
    return rc;
}

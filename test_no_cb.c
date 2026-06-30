#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include "libcheckisomd5.h"

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <iso>\n", argv[0]);
        return 1;
    }
    
    const char *iso = argv[1];
    
    printf("Checking %s with terminal settings...\n", iso);
    
    // Set up terminal like checkisomd5 does
    static struct termios oldt;
    struct termios newt;
    tcgetattr(0, &oldt);
    newt = oldt;
    newt.c_lflag &= ~(ICANON | ECHO | ECHONL | ISIG | IEXTEN);
    tcsetattr(0, TCSANOW, &newt);
    
    int rc = mediaCheckFile(iso, NULL, NULL);
    
    tcsetattr(0, TCSANOW, &oldt);
    
    printf("\nmediaCheckFile returned: %d\n", rc);
    
    return rc;
}

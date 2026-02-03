#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <sys/select.h>
#include "libcheckisomd5.h"

struct progressCBData {
    int verbose;
    int gauge;
    int gaugeat;
};

int user_bailing_out(void) {
    struct timeval timev;
    fd_set rfds;

    FD_ZERO(&rfds);
    FD_SET(0, &rfds);

    timev.tv_sec = 0;
    timev.tv_usec = 0;

    int select_result = select(1, &rfds, NULL, NULL, &timev);
    printf("[DEBUG: select returned %d]\n", select_result);
    
    if (select_result) {
        int ch = getchar();
        printf("[DEBUG: getchar returned %d]\n", ch);
        if (ch == 27)
            return 1;
    }

    return 0;
}

static int outputCB(void *const co, const long long offset, const long long total) {
    struct progressCBData *const data = co;
    double pct = (100.0 * (double) offset) / (double) total;
    
    if (pct > 100.0) pct = 100.0;

    if (data->verbose) {
        printf("\rChecking: %05.1f%%", pct);
        fflush(stdout);
    }
    
    int bail = user_bailing_out();
    if (bail) {
        printf("\n[DEBUG: User bailing out!]\n");
    }
    return bail;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <iso>\n", argv[0]);
        return 1;
    }
    
    const char *iso = argv[1];
    struct progressCBData data;
    memset(&data, 0, sizeof(data));
    data.verbose = 1;
    
    printf("Checking %s with callback...\n", iso);
    
    static struct termios oldt;
    struct termios newt;
    tcgetattr(0, &oldt);
    newt = oldt;
    newt.c_lflag &= ~(ICANON | ECHO | ECHONL | ISIG | IEXTEN);
    tcsetattr(0, TCSANOW, &newt);
    
    int rc = mediaCheckFile(iso, outputCB, &data);
    
    tcsetattr(0, TCSANOW, &oldt);
    
    printf("\nmediaCheckFile returned: %d\n", rc);
    
    return rc;
}

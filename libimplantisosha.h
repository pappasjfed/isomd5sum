#ifndef __LIBIMPLANTISOSHA_H__
#define __LIBIMPLANTISOSHA_H__

#ifdef __cplusplus
extern "C" {
#endif

int implantISOSHAFile(const char *iso, int supported, int forceit, int quiet, char **errstr);
int implantISOSHAFD(int isofd, int supported, int forceit, int quiet, char **errstr);

#ifdef __cplusplus
}
#endif

#endif


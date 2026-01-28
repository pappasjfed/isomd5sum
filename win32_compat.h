/*
 * Windows compatibility layer for POSIX functions
 * Copyright (C) 2024
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 */

#ifndef WIN32_COMPAT_H
#define WIN32_COMPAT_H

#ifdef _WIN32

#include <windows.h>
#include <io.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

/* Define O_BINARY if not already defined */
#ifndef O_BINARY
#define O_BINARY _O_BINARY
#endif

/* Map POSIX open flags to Windows equivalents */
#ifndef O_RDONLY
#define O_RDONLY _O_RDONLY
#endif

#ifndef O_WRONLY
#define O_WRONLY _O_WRONLY
#endif

#ifndef O_RDWR
#define O_RDWR _O_RDWR
#endif

#ifndef O_CREAT
#define O_CREAT _O_CREAT
#endif

#ifndef O_TRUNC
#define O_TRUNC _O_TRUNC
#endif

/* POSIX read/write/lseek replacements */
#define read _read
#define write _write
#define close _close
#define lseek _lseeki64
#define open _open

/* off_t definition for Windows */
typedef __int64 off_t;
typedef long ssize_t;

/* getpagesize() implementation */
static inline int getpagesize(void) {
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    return si.dwPageSize;
}

/* aligned_alloc implementation for older MSVC */
#if defined(_MSC_VER) && _MSC_VER < 1900
static inline void* aligned_alloc(size_t alignment, size_t size) {
    return _aligned_malloc(size, alignment);
}
#define free(ptr) _aligned_free(ptr)
#endif

/* Handle select and timeval for Windows */
#ifndef _WINSOCKAPI_
#include <winsock2.h>
#pragma comment(lib, "ws2_32.lib")
#endif

/* Macro to check if running on Windows */
#define IS_WINDOWS 1

#else

/* Not Windows */
#define IS_WINDOWS 0

#ifndef O_BINARY
#define O_BINARY 0
#endif

#endif /* _WIN32 */

#endif /* WIN32_COMPAT_H */

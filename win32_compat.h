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

/* POSIX read/write/close replacements */
#define read _read
#define write _write
#define close _close
#define open _open

/* Handle lseek - MinGW already defines it */
#ifndef __MINGW32__
#define lseek _lseeki64
#endif

/* off_t definition for Windows - only if not already defined */
/* Newer Windows SDK (UCRT) provides off_t, older versions don't */
#if !defined(__MINGW32__) && !defined(_OFF_T_DEFINED)
typedef __int64 off_t;
#define _OFF_T_DEFINED
#endif

/* ssize_t definition - only if not already defined */
/* Use intptr_t for correct size on 64-bit systems */
#if !defined(__MINGW32__) && !defined(_SSIZE_T_DEFINED)
#ifdef _WIN64
typedef __int64 ssize_t;
#else
typedef long ssize_t;
#endif
#define _SSIZE_T_DEFINED
#endif

/* getpagesize() implementation */
static inline int getpagesize(void) {
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    return si.dwPageSize;
}

/* aligned_alloc implementation for Windows */
/* MSVC doesn't provide aligned_alloc even in newer versions, so we need to use _aligned_malloc */
#if defined(_MSC_VER)
#include <malloc.h>
static inline void* aligned_alloc(size_t alignment, size_t size) {
    return _aligned_malloc(size, alignment);
}
#define NEED_ALIGNED_FREE 1
#endif

/* For MinGW, we need to provide aligned_alloc if not available */
#ifdef __MINGW32__
#include <malloc.h>
static inline void* aligned_alloc(size_t alignment, size_t size) {
    /* MinGW uses _aligned_malloc */
    return _aligned_malloc(size, alignment);
}
#define NEED_ALIGNED_FREE 1
#endif

/* Provide aligned_free wrapper for Windows */
#ifdef NEED_ALIGNED_FREE
static inline void aligned_free(void* ptr) {
    if (ptr) _aligned_free(ptr);
}
#else
/* On non-Windows, aligned_alloc uses regular malloc, so use regular free */
#define aligned_free(ptr) free(ptr)
#endif

/* Handle select and timeval for Windows */
#ifndef _WINSOCKAPI_
#include <winsock2.h>
#ifdef _MSC_VER
#pragma comment(lib, "ws2_32.lib")
#endif
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

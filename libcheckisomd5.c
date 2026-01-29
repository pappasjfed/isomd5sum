/*
 * Copyright (C) 2001-2013 Red Hat, Inc.
 *
 * Michael Fulbright <msf@redhat.com>
 * Dustin Kirkland  <dustin.dirkland@gmail.com>
 *      Added support for checkpoint fragment sums;
 *      Exits media check as soon as bad fragment md5sum'ed
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include "win32_compat.h"
#else
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#endif

#include "md5.h"
#include "libcheckisomd5.h"
#include "utilities.h"

static void clear_appdata(unsigned char *const buffer, const size_t size, const off_t appdata_offset, const off_t offset) {
    static const ssize_t buffer_start = 0;
    const ssize_t difference = appdata_offset - offset;
    if (-APPDATA_SIZE <= difference && difference <= (ssize_t) size) {
        const size_t clear_start = (size_t) MAX(buffer_start, difference);
        const size_t clear_len = MIN(size, (size_t)(difference + APPDATA_SIZE)) - clear_start;
        memset(buffer + clear_start, ' ', clear_len);
    }
}

static enum isomd5sum_status checkmd5sum(int isofd, checkCallback cb, void *cbdata) {
    struct volume_info *const info = parsepvd(isofd);
    if (info == NULL)
        return ISOMD5SUM_CHECK_NOT_FOUND;

    const int64_t total_size = info->isosize - info->skipsectors * SECTOR_SIZE;
    const int64_t fragment_size = total_size / (info->fragmentcount + 1);
    if (cb)
        cb(cbdata, 0LL, (long long) total_size);

    /* Rewind, compute md5sum. */
    lseek(isofd, 0LL, SEEK_SET);

    MD5_CTX hashctx;
    MD5_Init(&hashctx);

    const size_t buffer_size = NUM_SYSTEM_SECTORS * SECTOR_SIZE;
    unsigned char *buffer;
    buffer = aligned_alloc((size_t) getpagesize(), buffer_size * sizeof(*buffer));

    size_t previous_fragment = 0UL;
    int64_t offset = 0LL;
    int64_t total_bytes_read = 0LL;
    int read_count = 0;
    
#ifdef _WIN32
    /* Debug: Log file size and reading progress on Windows */
    fprintf(stderr, "DEBUG: Starting MD5 check - total_size=%lld bytes (%.2f GB)\n", 
            (long long)total_size, (double)total_size / (1024.0*1024.0*1024.0));
    fprintf(stderr, "DEBUG: Buffer size: %zu bytes\n", buffer_size);
    fprintf(stderr, "DEBUG: Expected number of reads: ~%lld\n", (long long)(total_size / buffer_size + 1));
#endif
    
    while (offset < total_size) {
        const size_t nbyte = MIN((size_t)(total_size - offset), buffer_size);

        ssize_t nread = read(isofd, buffer, nbyte);
        
#ifdef _WIN32
        read_count++;
        /* More frequent logging for first reads and periodic updates */
        if (read_count <= 20 || read_count % 500 == 0 || nread <= 0) {
            fprintf(stderr, "DEBUG: Read #%d: offset=%lld (%.2f%%), requested=%zu, got=%zd",
                    read_count, (long long)offset, 
                    (double)offset * 100.0 / (double)total_size,
                    nbyte, nread);
            if (nread > 0) {
                /* Show a sample of the data */
                fprintf(stderr, ", first 4 bytes: [%02x %02x %02x %02x]",
                        buffer[0], buffer[1], buffer[2], buffer[3]);
            }
            fprintf(stderr, "\n");
        }
#endif
        
        if (nread <= 0L) {
#ifdef _WIN32
            fprintf(stderr, "DEBUG: *** Read returned %zd at offset %lld (%.2f%% of file) ***\n",
                    nread, (long long)offset, (double)offset * 100.0 / (double)total_size);
            fprintf(stderr, "DEBUG: *** Expected to reach offset %lld but stopped early ***\n",
                    (long long)total_size);
            fprintf(stderr, "DEBUG: *** Total bytes successfully read: %lld (%.2f GB) ***\n",
                    (long long)total_bytes_read, (double)total_bytes_read / (1024.0*1024.0*1024.0));
            fprintf(stderr, "DEBUG: *** Missing %lld bytes (%.2f GB) ***\n",
                    (long long)(total_size - total_bytes_read),
                    (double)(total_size - total_bytes_read) / (1024.0*1024.0*1024.0));
#endif
            break;
        }
        
        total_bytes_read += nread;

        /**
         * Originally was added in 2005 because the kernel was returning the
         * size from where it started up to the end of the block it pre-fetched
         * from a cd drive.
         */
        if (nread > nbyte) {
            nread = nbyte;
            lseek(isofd, offset + nread, SEEK_SET);
        }
        /* Make sure appdata which contains the md5sum is cleared. */
        clear_appdata(buffer, nread, info->offset + APPDATA_OFFSET, offset);

        MD5_Update(&hashctx, buffer, (size_t) nread);
        if (info->fragmentcount) {
            const size_t current_fragment = offset / fragment_size;
            const size_t fragmentsize = FRAGMENT_SUM_SIZE / info->fragmentcount;
            /* If we're onto the next fragment, calculate the previous sum and check. */
            if (current_fragment != previous_fragment) {
                if (!validate_fragment(&hashctx, current_fragment, fragmentsize,
                                       info->fragmentsums, NULL)) {
                    /* Exit immediately if current fragment sum is incorrect */
                    free(info);
                    aligned_free(buffer);
                    return ISOMD5SUM_CHECK_FAILED;
                }
                previous_fragment = current_fragment;
            }
        }
        offset += nread;
        if (cb)
            if (cb(cbdata, (long long) offset, (long long) total_size)) {
                free(info);
                aligned_free(buffer);
                return ISOMD5SUM_CHECK_ABORTED;
            }
    }
    aligned_free(buffer);

#ifdef _WIN32
    fprintf(stderr, "DEBUG: ======== READ COMPLETE ========\n");
    fprintf(stderr, "DEBUG: Total reads performed: %d\n", read_count);
    fprintf(stderr, "DEBUG: Total bytes read: %lld / %lld (%.2f%%)\n",
            (long long)total_bytes_read, (long long)total_size,
            (double)total_bytes_read * 100.0 / (double)total_size);
    fprintf(stderr, "DEBUG: Final offset: %lld\n", (long long)offset);
    if (total_bytes_read < total_size) {
        fprintf(stderr, "DEBUG: *** WARNING: Incomplete read! Missing %lld bytes ***\n",
                (long long)(total_size - total_bytes_read));
    }
#endif

    if (cb)
        cb(cbdata, (long long) info->isosize, (long long) total_size);

    char hashsum[HASH_SIZE + 1];
    md5sum(hashsum, &hashctx);

#ifdef _WIN32
    fprintf(stderr, "DEBUG: Calculated MD5: %s\n", hashsum);
    fprintf(stderr, "DEBUG: Expected MD5:   %s\n", info->hashsum);
    fprintf(stderr, "DEBUG: Match: %s\n", strcmp(info->hashsum, hashsum) == 0 ? "YES" : "NO");
#endif

    int failed = strcmp(info->hashsum, hashsum);
    free(info);
    return failed ? ISOMD5SUM_CHECK_FAILED : ISOMD5SUM_CHECK_PASSED;
}

int mediaCheckFile(const char *file, checkCallback cb, void *cbdata) {
    int isofd = open(file, O_RDONLY | O_BINARY);
    if (isofd < 0) {
        return ISOMD5SUM_FILE_NOT_FOUND;
    }
    int rc = checkmd5sum(isofd, cb, cbdata);
    close(isofd);
    return rc;
}

int mediaCheckFD(int isofd, checkCallback cb, void *cbdata) {
    return checkmd5sum(isofd, cb, cbdata);
}

int printMD5SUM(const char *file) {
    int isofd = open(file, O_RDONLY | O_BINARY);
    if (isofd < 0) {
        return ISOMD5SUM_FILE_NOT_FOUND;
    }
    struct volume_info *const info = parsepvd(isofd);
    close(isofd);
    if (info == NULL) {
        return ISOMD5SUM_CHECK_NOT_FOUND;
    }

    printf("%s:   %s\n", file, info->hashsum);
    if (strlen(info->fragmentsums) > 0 && info->fragmentcount > 0) {
        printf("Fragment sums: %s\n", info->fragmentsums);
        printf("Fragment count: %zu\n", info->fragmentcount);
        printf("Supported ISO: %s\n", info->supported ? "yes" : "no");
    }
    fflush(stdout);
    free(info);
    return 0;
}

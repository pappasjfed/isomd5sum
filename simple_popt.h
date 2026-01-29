/*
 * Simple popt-compatible command line parser for Windows
 * Copyright (C) 2024
 *
 * This provides a minimal subset of popt functionality for Windows builds
 */

#ifndef SIMPLE_POPT_H
#define SIMPLE_POPT_H

#ifdef _WIN32

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define POPT_ARG_NONE 0
#define POPT_ARG_STRING 1
#define POPT_ARG_INT 2
#define POPT_ARG_LONG 3

#define POPT_BADOPTION_NOALIAS 0

struct poptOption {
    const char *longName;
    char shortName;
    int argInfo;
    void *arg;
    int val;
};

typedef struct {
    int argc;
    const char **argv;
    int current;
    const struct poptOption *options;
    const char *badOption;
} *poptContext;

static inline poptContext poptGetContext(const char *name, int argc, const char **argv, 
                                         const struct poptOption *options, int flags) {
    poptContext ctx = malloc(sizeof(*ctx));
    if (!ctx) return NULL;
    
    ctx->argc = argc;
    ctx->argv = argv;
    ctx->current = 1;  /* Skip program name */
    ctx->options = options;
    ctx->badOption = NULL;
    return ctx;
}

static inline int poptGetNextOpt(poptContext ctx) {
    if (ctx->current >= ctx->argc) {
        return -1;
    }
    
    const char *arg = ctx->argv[ctx->current];
    
    /* Not an option or NULL */
    if (!arg || arg[0] != '-') {
        return -1;
    }
    
    /* Check for empty option strings */
    if (arg[1] == '\0') {
        return -1;
    }
    
    int isLong = (arg[1] == '-');
    
    /* Handle bare "--" */
    if (isLong && arg[2] == '\0') {
        return -1;
    }
    
    const char *optName = isLong ? arg + 2 : arg + 1;
    
    /* Search for matching option */
    for (const struct poptOption *opt = ctx->options; opt->longName || opt->shortName; opt++) {
        int match = 0;
        
        if (isLong && opt->longName && strcmp(optName, opt->longName) == 0) {
            match = 1;
        } else if (!isLong && opt->shortName && optName[0] == opt->shortName && optName[1] == '\0') {
            match = 1;
        }
        
        if (match) {
            if (opt->argInfo == POPT_ARG_NONE && opt->arg) {
                *(int *)opt->arg = 1;
            }
            ctx->current++;
            return opt->val;
        }
    }
    
    ctx->badOption = arg;
    ctx->current++;
    return -2;  /* Bad option */
}

static inline const char **poptGetArgs(poptContext ctx) {
    if (ctx->current >= ctx->argc) {
        return NULL;
    }
    return &ctx->argv[ctx->current];
}

static inline const char *poptBadOption(poptContext ctx, int flags) {
    return ctx->badOption ? ctx->badOption : "";
}

static inline const char *poptStrerror(int error) {
    return "Invalid option";
}

static inline void poptFreeContext(poptContext ctx) {
    free(ctx);
}

#else

/* On non-Windows systems, use the real popt library */
#include <popt.h>

#endif /* _WIN32 */

#endif /* SIMPLE_POPT_H */

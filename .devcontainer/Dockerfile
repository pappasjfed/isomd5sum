FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# ──────────────────────────────────────────────────────────────────
# Core build toolchain
# ──────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc \
        g++ \
        make \
        cmake \
        ninja-build \
        pkg-config \
        # popt — required by all four checker/implanter CLIs
        libpopt-dev \
    && rm -rf /var/lib/apt/lists/*

# ──────────────────────────────────────────────────────────────────
# Python — needed for the pyisomd5sum binding and all test scripts
# ──────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*

# ──────────────────────────────────────────────────────────────────
# ISO creation and inspection tools
#   xorriso  — used in CI to create test ISOs
#   genisoimage — provides mkisofs + isoinfo for ISO inspection
# ──────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        xorriso \
        genisoimage \
    && rm -rf /var/lib/apt/lists/*

# ──────────────────────────────────────────────────────────────────
# Signing tools
#   gnupg / gpg-agent — GPG signing of release tarballs and artifacts
#   osslsigncode      — Authenticode (PE) signing of Windows .exe/.dll
#                       from Linux (used for the Windows installer)
# ──────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        gnupg \
        gpg-agent \
        osslsigncode \
    && rm -rf /var/lib/apt/lists/*

# ──────────────────────────────────────────────────────────────────
# Windows cross-compilation
#   mingw-w64  — full GCC cross-toolchain (x86_64-w64-mingw32-gcc, etc.)
#                needed to test the cmake/mingw-w64.cmake toolchain file
# ──────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        mingw-w64 \
        nsis \
    && rm -rf /var/lib/apt/lists/*

# ──────────────────────────────────────────────────────────────────
# Debugging and analysis
#   gdb      — source-level C debugger
#   valgrind — memory-error and leak detection
#   strace   — syscall tracing (useful when debugging file-I/O paths)
#   ltrace   — library-call tracing
# ──────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        gdb \
        valgrind \
        strace \
        ltrace \
    && rm -rf /var/lib/apt/lists/*

# ──────────────────────────────────────────────────────────────────
# Code quality and formatting
#   clang-format  — driven by .clang-format in the repo root
#   clang-tidy    — static analysis
#   shellcheck    — lints the test/*.sh scripts
# ──────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        clang \
        clang-format \
        clang-tidy \
        shellcheck \
    && rm -rf /var/lib/apt/lists/*

# ──────────────────────────────────────────────────────────────────
# Documentation tools
#   groff / man-db — render and browse installed man pages
# ──────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        man-db \
        groff \
    && rm -rf /var/lib/apt/lists/*

# ──────────────────────────────────────────────────────────────────
# General utilities
#   binutils   — objdump, nm, readelf, strings, etc.
#   util-linux — fallocate for sparse-file generation in large-file tests
#   file       — identify file types
#   zip / bzip2 / xz-utils — archive formats used in release packaging
# ──────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        binutils \
        util-linux \
        file \
        zip \
        unzip \
        bzip2 \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

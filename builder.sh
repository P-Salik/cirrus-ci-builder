#!/usr/bin/env bash

# Helper function for cloning
gut() {
	git clone --depth=1 -q $@
}

# Toolchains directory
mkdir toolchains

# Clone GCC
gut https://github.com/mvaisakh/gcc-arm64 toolchains/gcc64
gut https://github.com/mvaisakh/gcc-arm toolchains/gcc

# Clone AnyKernel3
gut https://github.com/P-Salik/AnyKernel3.git AnyKernel3

# Clone Kernel Source
gut https://github.com/P-Salik/RMX1941_kernel Kernel

# Setup Scripts
mv kernel.sh Kernel/kernel.sh
cd Kernel

# Compile the kernel using CLANG
bash kernel.sh

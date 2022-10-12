#!/usr/bin/env bash

# Helper function for cloning
gut() {
	git clone --depth=1 -q $@
}

# Toolchains directory
mkdir toolchains

# Clone GCC
gut https://github.com/sarthakroy2002/prebuilts_gcc_linux-x86_aarch64_aarch64-linaro-7 toolchains/gcc64
gut https://github.com/sarthakroy2002/linaro_arm-linux-gnueabihf-7.5 toolchains/gcc32

# Clone CLANG
gut https://github.com/P-Salik/android_prebuilts_clang_host_linux-x86_clang-5484270 toolchains/clang

# Clone AnyKernel3
gut https://github.com/P-Salik/AnyKernel3.git AnyKernel3

# Clone Kernel Source
gut https://github.com/P-Salik/android_kernel_realme_RMX1941 Kernel

# Setup Scripts
mv kernel.sh Kernel/kernel.sh
cd Kernel

# Compile the kernel using CLANG
bash kernel.sh

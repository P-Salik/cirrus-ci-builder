#!/usr/bin/env bash
# Copyright (c) 2021-2022, Tashfin Shakeer Rhythm <tashfinshakeerrhythm@gmail.com>
# Revision: 04-10-2022 V7.1

set -e

# Colors
R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
W='\033[1;37m'

# User infomation
USER='P-Salik'
HOST='Cirrus'
TOKEN=${TG_TOKEN}
CHATID=${CHAT_ID}
BOT_MSG_URL="https://api.telegram.org/bot$TOKEN/sendMessage"
BOT_BUILD_URL="https://api.telegram.org/bot$TOKEN/sendDocument"

# Device configuration
NAME='Realme C2'
CODENAME='RMX1941'
DCFG="RMX1941_defconfig"
REGEN='1'

# Paths
KERNEL_DIR=$(pwd)
TOOLCHAIN="$KERNEL_DIR/../toolchains"
ZIP_DIR="$KERNEL_DIR/../AnyKernel3"
AKSH="$ZIP_DIR/anykernel.sh"
cd $KERNEL_DIR

# Defconfig
CONFIG="$KERNEL_DIR/arch/arm64/configs/${DCFG}"


# Flags to be passed to compile
pass() {
	CC='clang'
	CC_TRIPLE='aarch64-linux-gnu-'
	GCC_64="$TOOLCHAIN/gcc64/bin/aarch64-linux-gnu-"
	GCC_32="$TOOLCHAIN/gcc32/bin/arm-linux-gnueabihf-"
	C_PATH="$TOOLCHAIN/clang"
	regen
}
export PATH=$C_PATH/bin:$PATH

# Helper function to print error message
error() {
	echo -e ""
	echo -e "$R Error! $Y$1"
	echo -e ""
	exit 1
}

# Function to pass compilation flags
muke() {
	make O=work $CFLAG ARCH=arm64 $FLAG \
		CC=$CC \
		KBUILD_BUILD_USER=$USER \
		KBUILD_BUILD_HOST=$HOST \
		PATH=$C_PATH/bin:$PATH \
		CLANG_TRIPLE=$CC_TRIPLE \
		CROSS_COMPILE=$GCC_64 \
		CROSS_COMPILE_ARM32=$GCC_32 \
		CONFIG_NO_ERROR_ON_MISMATCH=y \
		2>&1 | tee log.txt
}

regen() {
	if [[ $REGEN == '1' ]]; then
		CFLAG="$DCFG"
		muke
		cp work/.config $CONFIG
		git add $CONFIG
		git commit -s -m "defconfig: Regenerate"
		git push
	fi
	compile
}

# Functions to send messages/files to telegram
tg_post_msg() {
	curl -s -X POST "$BOT_MSG_URL" -d chat_id="$CHATID" \
		-d "disable_web_page_preview=true" \
		-d "parse_mode=html" \
		-d text="$1"
}

tg_post_build() {
	#Post MD5Checksum alongwith for easeness
	MD5CHECK=$(md5sum "$1" | cut -d' ' -f1)

	#Show the Checksum alongwith caption
	curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
		-F chat_id="$CHATID" \
		-F "disable_web_page_preview=true" \
		-F "parse_mode=html" \
		-F caption="$2 | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
}

# Let the compilation begin
compile() {
	CFLAG=$DCFG
	muke

	echo -e "$B"
	echo -e "                Build started                "
	echo -e "$G"

	BUILD_START=$(date +"%s")

	CFLAG=-j$(nproc --all)
	muke

	# Compilation ends
	BUILD_END=$(date +"%s")

	echo -e "$B"
	echo -e "                Zipping started                "
	echo -e "$W"
	check
}

# Check for AnyKernel3
check() {
	if [[ -f $KERNEL_DIR/work/arch/arm64/boot/Image.gz-dtb ]]; then
		if [[ -d $ZIP_DIR ]]; then
			zip_ak
		else
			error 'Anykernel is not present, cannot zip'
		fi
	else
		tg_post_build "log.txt" "Build failed!!"
		error 'Kernel image not found!!'
	fi
}

# Pack the image-gz.dtb using AnyKernel3
zip_ak() {
	source work/.config

	DEVICE=${CODENAME^^}
	KV=$(cat $KERNEL_DIR/work/include/generated/utsrelease.h | cut -c 21- | tr -d '"')

	cp $KERNEL_DIR/work/arch/arm64/boot/Image.gz-dtb $ZIP_DIR/

# Post the log after a successful build
	tg_post_build "log.txt" "Compiled kernel successfully!!"

	cd $ZIP_DIR

	FINAL_ZIP="${DEVICE}-${KV}-$(date +%Y%d%H)"
	zip -r9 "$FINAL_ZIP.zip" * -x README.md LICENSE
	FINAL_ZIP="$FINAL_ZIP.zip"

# Post the kernel zip
	tg_post_build "$FINAL_ZIP"

	cd $KERNEL_DIR

	DIFF=$(($BUILD_END - $BUILD_START))
	CONFIG_CC_VERSION_TEXT=$(head -n 1 $C_PATH/AndroidVersion.txt)
	COMMIT_NAME=$(git show -s --format=%s)
	COMMIT_HASH=$(git rev-parse --short HEAD)

# Print the build information
	tg_post_msg "
	=========TEST Kernel=========
	Compiler: <code>Clang $CONFIG_CC_VERSION_TEXT</code>
	Linux Version: <code>$KV</code>
	Maintainer: <code>$USER</code>
	Device: <code>$NAME</code>
	Codename: <code>$DEVICE</code>
	Zipname: <code>$FINAL_ZIP</code>
	Build Date: <code>$(date +"%Y-%m-%d %H:%M")</code>
	Build Duration: <code>$(($DIFF / 60)).$(($DIFF % 60)) mins</code>
	Last Commit Name: <code>$COMMIT_NAME</code>
	Last Commit Hash: <code>$COMMIT_HASH</code>
	"
	exit 0
}

pass

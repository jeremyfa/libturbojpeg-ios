#!/bin/bash

brew install libtool automake autoconf nasm git

mkdir libjpeg-turbo

cd libjpeg-turbo

mkdir libs

rm -rf src
git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git src

cd src

autoreconf -fi

IOS_PLATFORMDIR=$(xcrun --sdk iphoneos --show-sdk-platform-path)
IOS_SYSROOT=$(xcrun --sdk iphoneos --show-sdk-path)
IOS_SIMULATOR_PLATFORMDIR=$(xcrun --sdk iphonesimulator --show-sdk-platform-path)
IOS_SIMULATOR_SYSROOT=$(xcrun --sdk iphonesimulator --show-sdk-path)
IOS_GCC=$(/usr/bin/xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang

## armv7
echo "--- Building for armv7 ---"
IOS_CFLAGS="-arch armv7 -miphoneos-version-min=8.0"
export CFLAGS="-mfloat-abi=softfp -isysroot $IOS_SYSROOT -O3 $IOS_CFLAGS -fembed-bitcode"
export ASMFLAGS="-no-integrated-as"

cat <<EOF >toolchain.cmake
set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_SYSTEM_PROCESSOR arm)
set(CMAKE_C_COMPILER /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang)
EOF

cmake -G"Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=toolchain.cmake \
  -DCMAKE_OSX_SYSROOT=${IOS_SYSROOT[0]} \
  .
make
mv -v ./libturbojpeg.a ../libs/libturbojpeg_armv7_a

cd ..
rm -rf src
git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git src
cd src

## arm64
echo "--- Building for arm64 ---"
IOS_CFLAGS="-arch arm64 -miphoneos-version-min=8.0"
export CFLAGS="-Wall -isysroot $IOS_SYSROOT -O3 $IOS_CFLAGS -fembed-bitcode -funwind-tables"
export ASMFLAGS=""

cat <<EOF >toolchain.cmake
set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_C_COMPILER /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang)
EOF

cmake -G"Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=toolchain.cmake \
  -DCMAKE_OSX_SYSROOT=${IOS_SYSROOT[0]} \
  .
make
mv -v ./libturbojpeg.a ../libs/libturbojpeg_arm64_a

cd ..
rm -rf src
git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git src
cd src

## i386 (32-bit Build on 64-bit OS X ==> i686)
echo "--- Building for i386 (32-bit Build on 64-bit OS X ==> i686) ---"
IOS_CFLAGS="-arch i386 -miphonesimulator-version-min=8.0"
export CFLAGS="-m32 $IOS_CFLAGS -isysroot $IOS_SIMULATOR_SYSROOT"
export ASMFLAGS=""
export LDFLAGS="-m32"
export NASM=/usr/local/bin/nasm

cat <<EOF >toolchain.cmake
set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_SYSTEM_PROCESSOR i386)
set(CMAKE_C_COMPILER /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang)
EOF

cmake -G"Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=toolchain.cmake \
  -DCMAKE_OSX_SYSROOT=${IOS_SIMULATOR_SYSROOT[0]} \
  .
make
mv -v ./libturbojpeg.a ../libs/libturbojpeg_x86_a

cd ..
rm -rf src
git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git src
cd src

##  x86_64
echo "--- Building for x86_64 ---"
IOS_CFLAGS="-arch x86_64 -miphonesimulator-version-min=8.0"
export CFLAGS="$IOS_CFLAGS -isysroot $IOS_SIMULATOR_SYSROOT"
export ASMFLAGS=""
export LDFLAGS=""
export NASM=/usr/local/bin/nasm

cat <<EOF >toolchain.cmake
set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(CMAKE_C_COMPILER /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang)
EOF

cmake -G"Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=toolchain.cmake \
  -DCMAKE_OSX_SYSROOT=${IOS_SIMULATOR_SYSROOT[0]} \
  .
make
mv -v ./libturbojpeg.a ../libs/libturbojpeg_x86_64_a

## lipo
mkdir -p ../libs/ios/device
mkdir -p ../libs/ios/simulator
mkdir -p ../libs/ios/universal

# Device fat binary
xcrun -sdk iphoneos lipo -arch armv7 ../libs/libturbojpeg_armv7_a -arch arm64 ../libs/libturbojpeg_arm64_a -create -output ../libs/ios/device/libturbojpeg.a
# Simulator fat binary
xcrun -sdk iphoneos lipo -arch i386 ../libs/libturbojpeg_x86_a -arch x86_64 ../libs/libturbojpeg_x86_64_a -create -output ../libs/ios/simulator/libturbojpeg.a
# Universal fat binary
xcrun -sdk iphoneos lipo -arch armv7 ../libs/libturbojpeg_armv7_a -arch arm64 ../libs/libturbojpeg_arm64_a -arch i386 ../libs/libturbojpeg_x86_a -arch x86_64 ../libs/libturbojpeg_x86_64_a -create -output ../libs/ios/universal/libturbojpeg.a
# Removing thin binaries
rm -f ../libs/*_a

cd ..
rm -rf src

# Toolchain file for cross-compiling to Raspberry Pi 4 64-bit (ARM64)
# Usage: cmake -DCMAKE_TOOLCHAIN_FILE=raspi-toolchain.cmake ..

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Specify the cross compiler for ARM64
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

# Specify the sysroot
# Update this path to point to your Raspberry Pi sysroot
set(CMAKE_SYSROOT /home/jacob/sysroot)

# Set the search paths
set(CMAKE_FIND_ROOT_PATH /home/jacob/sysroot)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Qt6 installation path for Raspberry Pi
# Update this to point to your Qt6 installation compiled for Raspberry Pi
set(CMAKE_PREFIX_PATH "/home/jacob/sysroot/usr/lib/aarch64-linux-gnu/cmake")
set(Qt6_DIR "/home/jacob/sysroot/usr/lib/aarch64-linux-gnu/cmake/Qt6")

# Use Qt 6.4.2 host tools to match Pi version
set(QT_HOST_PATH "/opt/Qt/6.4.2/gcc_64")
set(QT_HOST_TOOLS_DIRECTORY "/opt/Qt/6.8.3/gcc_64/bin")

# Raspberry Pi 4 64-bit specific settings
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mcpu=cortex-a72")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mcpu=cortex-a72")

# For other Pi models (32-bit), use these instead:
# Pi 4 32-bit: -mcpu=cortex-a72 -mfpu=neon-fp-armv8 -mfloat-abi=hard
# Pi 3 32-bit: -mcpu=cortex-a53 -mfpu=neon-fp-armv8 -mfloat-abi=hard
# Pi 1/Zero 32-bit: -mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard

cmake_minimum_required(VERSION 3.16)

project(UntitledProjectApp LANGUAGES CXX)

# Cross-compilation settings for Raspberry Pi 4 64-bit
if(CMAKE_CROSSCOMPILING)
    message(STATUS "Cross-compiling for Raspberry Pi 4 64-bit (ARM64)")
    
    # Set the target architecture
    set(CMAKE_SYSTEM_NAME Linux)
    set(CMAKE_SYSTEM_PROCESSOR aarch64)
    
    # Raspberry Pi 4 64-bit specific compiler settings
    set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
    set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
    
    # Set the sysroot (adjust path to your Raspberry Pi sysroot)
    # set(CMAKE_SYSROOT /home/jacob/sysroot)
    # set(CMAKE_FIND_ROOT_PATH /home/jacob/sysroot)
    set(CMAKE_SYSROOT /home/seame/sysroot)
    set(CMAKE_FIND_ROOT_PATH /home/seame/sysroot)

    # Configure search paths for cross-compilation
    set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
    set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
    
    # Qt6 path for Raspberry Pi (adjust to your Qt6 installation for Pi)
    # set(CMAKE_PREFIX_PATH "/home/jacob/sysroot/usr/lib/aarch64-linux-gnu/cmake")
    set(CMAKE_PREFIX_PATH "/home/seame/sysroot/usr/lib/aarch64-linux-gnu/cmake")
endif()

# Standard CMake settings
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set build type specific definitions
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_definitions(-DQT_NO_DEBUG_OUTPUT)
    add_definitions(-DQT_NO_INFO_OUTPUT)
    add_definitions(-DQT_NO_WARNING_OUTPUT)
endif()

# QML settings for cross-compilation
if(CMAKE_CROSSCOMPILING)
    set(QT_FEATURE_qml_jit OFF)
    # Don't disable cache generation completely - it's needed for type registration
    # set(QT_NO_QMLCACHE_GENERATION ON)
endif()

# Find Qt6 components
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 DBus)

# Create the executable
qt_add_executable(UntitledProjectApp 
    src/main.cpp
    src/canreceiver.cpp
    src/canreceiver.h
    src/dbusreceiver.cpp
    src/dbusreceiver.h
)

# Add Qt6 policies for better compatibility (commented out for compatibility)
# qt_policy(SET QTP0001 NEW)

# Add configuration resources
qt_add_resources(UntitledProjectApp "configuration"
    PREFIX "/"
    FILES
        qtquickcontrols2.conf
)

# Link Qt6 libraries
target_link_libraries(UntitledProjectApp PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::QuickControls2
    Qt6::DBus
)

# Raspberry Pi 4 64-bit specific optimizations
if(CMAKE_CROSSCOMPILING)
    # Add Raspberry Pi 4 64-bit specific compiler flags
    target_compile_options(UntitledProjectApp PRIVATE
        -mcpu=cortex-a72  # Raspberry Pi 4 CPU
        -O2
    )
    
    # Add ARM64 specific linker flags
    target_link_options(UntitledProjectApp PRIVATE
        -Wl,-rpath-link,${CMAKE_SYSROOT}/usr/lib/aarch64-linux-gnu
        -Wl,-rpath-link,${CMAKE_SYSROOT}/lib/aarch64-linux-gnu
    )
endif()

# Include QML modules
include(${CMAKE_CURRENT_SOURCE_DIR}/qmlmodules)

# Installation settings for Raspberry Pi
if(CMAKE_CROSSCOMPILING)
    install(TARGETS UntitledProjectApp
        RUNTIME DESTINATION bin
    )
    
endif()

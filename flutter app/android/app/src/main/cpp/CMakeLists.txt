cmake_minimum_required(VERSION 3.4.1)
# Specify the location of the OpenSSL installation for Android

# Add the native library
add_library(
        native-lib  # Library name
        SHARED
        func.c      # Your C/C++ file
)

# Link against the OpenSSL libraries
target_link_libraries(
        native-lib
        log
        ${log-lib}
)

find_library( # Defines the name of the path variable that stores the
        # location of the NDK library.
        log-lib

        # Specifies the name of the NDK library that
        # CMake needs to locate.
        log )
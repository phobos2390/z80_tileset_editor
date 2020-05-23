cmake_minimum_required(VERSION 3.5.0)

set(PROJ_DIR ${CMAKE_CURRENT_SOURCE_DIR})

set(CMAKE_C_COMPILER "/usr/bin/clang")
set(CMAKE_CXX_COMPILER "/usr/bin/clang++")

add_subdirectory("${PROJ_DIR}/z80_sdl_emulator")

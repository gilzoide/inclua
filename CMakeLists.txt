## Inclua CMake build script ##

project (inclua)

cmake_minimum_required (VERSION 2.6)
set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake")

option(TEMPLATE_PATH_PREFIX "Prefix of path to store wrapper templates")

find_package (Clang REQUIRED)
find_package (Lua REQUIRED)
add_subdirectory (src)

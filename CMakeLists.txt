## Inclua CMake build script ##

project (inclua)

cmake_minimum_required (VERSION 2.6)
set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake")

option(TEMPLATE_PATH_PREFIX "Prefix of path to store wrapper templates")

find_package (Lua QUIET)
if(NOT Lua_FOUND)
	message(STATUS "Couldn't find systemwide Lua installation, using Luarocks defined variables")
	set(LUA_LIBRARIES ${LUALIB})
	set(LUA_INCLUDE_DIR ${LUA_INCDIR})
endif()
find_package (Clang REQUIRED)
add_subdirectory (src)

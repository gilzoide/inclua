#[[.rst:
# FindClang
# ==========
# 
# Find clang.
# 
# Defines the following variables:
# 
# - CLANG_FOUND - if clang was found
# - CLANG_VERSION - clang version
# - CLANG_INCLUDE_DIR - libclang include directory
# - CLANG_C_INCLUDE_DIR - libclang C include directory
# - CLANG_LIBRARY - libclang library
# - CLANG_EXECUTABLE - clang executable path
#]]

set (_clang_names clang-5.0 clang-4.0 clang-3.9 clang-3.8
	clang-3.7 clang-3.6 clang-3.5 clang)

# headers
find_path (CLANG_INCLUDE_DIR NAMES clang/Basic/Version.h)
find_path (CLANG_C_INCLUDE_DIR NAMES clang-c/Index.h)
# lib
find_library (CLANG_LIBRARY NAMES ${_clang_names})
# executable
find_program (CLANG_EXECUTABLE NAMES ${_clang_names})
if (CLANG_EXECUTABLE)
	execute_process (COMMAND ${CLANG_EXECUTABLE} --version
		OUTPUT_VARIABLE _CLANG_VERSION
		OUTPUT_STRIP_TRAILING_WHITESPACE)
	string (REGEX MATCH "[0-9]\\.[0-9]\\.[0-9]" CLANG_VERSION ${_CLANG_VERSION})
endif ()


# Handle QUIET and REQUIRED, and set version string
include (FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS (Clang
	REQUIRED_VARS CLANG_LIBRARY CLANG_EXECUTABLE CLANG_INCLUDE_DIR
	VERSION_VAR CLANG_VERSION)


#[[.rst:
FindInclua
==========

Find inclua.

Defines the following variables

- INCLUA_FOUND - If inclua was found
- INCLUA_VERSION - Inclua version
- INCLUA_EXECUTABLE - Inclua executable path
#]]

find_program (INCLUA_EXECUTABLE NAMES inclua)

if (INCLUA_EXECUTABLE)
	# find inclua version
	execute_process (COMMAND ${INCLUA_EXECUTABLE} -v
		OUTPUT_VARIABLE INCLUA_VERSION
		OUTPUT_STRIP_TRAILING_WHITESPACE)
	set (INCLUA_USE_FILE ${CMAKE_CURRENT_LIST_DIR}/UseInclua.cmake)

	# find clang include directory and add it to include paths
	# needed for important clang definitions, like size_t, for example
	find_program (_CLANG_EXECUTABLE NAMES clang clang-4.0 clang-3.9 clang-3.8
		clang-3.7 clang-3.6 clang-3.5)
	execute_process (COMMAND ${_CLANG_EXECUTABLE} --version
		OUTPUT_VARIABLE _CLANG_VERSION
		OUTPUT_STRIP_TRAILING_WHITESPACE)
	string (REGEX MATCH "[0-9]\\.[0-9]\\.[0-9]" _CLANG_VERSION ${_CLANG_VERSION})
	find_path (INCLUA_CLANG_INCLUDE_PATH
		NAMES stddef.h
		PATH_SUFFIXES "clang/${_CLANG_VERSION}/include"
		PATHS
		/usr/local/lib
		/usr/lib
		/lib)
	if (INCLUA_CLANG_INCLUDE_PATH STREQUAL "INCLUA_CLANG_INCLUDE_PATH-NOTFOUND")
		message (WARNING "Couldn't find clang include path, which could lead in errors with implementation defined C types (like size_t)")
	endif ()
	# hide internal variables
	mark_as_advanced (INCLUA_CLANG_VERSION
		INCLUA_CLANG_INCLUDE_PATH
		INCLUA_CLANG_INCLUDE_FLAG)
endif()

# Handle QUIET and REQUIRED, and set version string
include (FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS (Inclua
	REQUIRED_VARS INCLUA_EXECUTABLE
	VERSION_VAR INCLUA_VERSION)

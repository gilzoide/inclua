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
	execute_process (COMMAND ${INCLUA_EXECUTABLE} -clv
		OUTPUT_VARIABLE INCLUA_CLANG_VERSION
		OUTPUT_STRIP_TRAILING_WHITESPACE)
	find_path (INCLUA_CLANG_INCLUDE_PATH
		NAMES stddef.h
		PATH_SUFFIXES "clang/${INCLUA_CLANG_VERSION}/include"
		PATHS
		/usr/local/lib
		/usr/lib
		/lib)
	if (INCLUA_CLANG_INCLUDE_PATH)
		set (INCLUA_CLANG_INCLUDE_FLAG "-I${INCLUA_CLANG_INCLUDE_PATH}")
	else ()
		set (INCLUA_CLANG_INCLUDE_FLAG "")
	endif()

	# hide internal variables
	mark_as_advanced (INCLUA_CLANG_VERSION
		INCLUA_CLANG_INCLUDE_PATH
		INCLUA_CLANG_INCLUDE_FLAG)
endif()

# Handle QUIET and REQUIRED, and set version string
include (FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS (INCLUA
	REQUIRED_VARS INCLUA_EXECUTABLE
	VERSION_VAR INCLUA_VERSION)

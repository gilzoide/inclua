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
endif()

# Handle QUIET and REQUIRED, and set version string
include (FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS (INCLUA
	REQUIRED_VARS INCLUA_EXECUTABLE
	VERSION_VAR INCLUA_VERSION)

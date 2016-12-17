#[[.rst:
UseInclua
=========

Generate wrappers with inclua.
Defines the following macros

- INCLUA_ADD_MODULE(name language input_file [ flags ])
- INCLUA_LINK_LIBRARIES(name [ libraries ])

Configuration variables are:

- INCLUA_OUTPUT_EXTENSION: generated wrapper file extension. The default is "cpp"
- INCLUA_OUTPUT_DIRECTORY: built library output directory, created at runtime
- INCLUA_INCLUDE_DIRECTORIES: include directories for compiling the resulting library
#]]

macro (INCLUA_ADD_MODULE name language input_file)
	get_filename_component (_inclua_input ${input_file} ABSOLUTE)
	get_filename_component (_inclua_local_dir ${_inclua_input} DIRECTORY)
	# first, check if extension is specified. Default = C++
	if (NOT INCLUA_OUTPUT_EXTENSION)
		set (INCLUA_OUTPUT_EXTENSION "cpp")
	endif ()
	# output is input with the extension changed
	string (REGEX REPLACE "\\.[^.]+$" ".${INCLUA_OUTPUT_EXTENSION}" _inclua_output "${input_file}")

	# run inclua command
	add_custom_command (OUTPUT ${_inclua_output}
		COMMAND ${INCLUA_EXECUTABLE} -o ${_inclua_output} -l ${language} ${_inclua_input} ${INCLUA_CLANG_INCLUDE_FLAG} -I${_inclua_local_dir} ${ARGN}
		DEPENDS ${_inclua_input}
		COMMENT "Inclua module definition")
	# proxy name for target
	set (INCLUA_${name}_WRAPPER ${name})
	add_library (${INCLUA_${name}_WRAPPER} MODULE ${_inclua_output})
	target_include_directories (${INCLUA_${name}_WRAPPER} PUBLIC ${_inclua_local_dir})
	# remove the "lib" prefix on Unix systems, and set output and include directories
	set_target_properties (${INCLUA_${name}_WRAPPER} PROPERTIES
		PREFIX ""
		LIBRARY_OUTPUT_DIRECTORY "${INCLUA_OUTPUT_DIRECTORY}"
		LIBRARY_INCLUDE_DIRECTORIES "${INCLUA_INCLUDE_DIRECTORIES}")
endmacro()

# link libraries to the generated wrappers
macro (INCLUA_LINK_LIBRARIES name)
	if (INCLUA_${name}_WRAPPER)
		target_link_libraries (${INCLUA_${name}_WRAPPER} ${ARGN})
	else ()
		message (SEND_ERROR "Inclua module \"${name}\" not found")
	endif()
endmacro()

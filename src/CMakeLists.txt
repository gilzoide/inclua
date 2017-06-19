# C++ visitor
file (GLOB cppSrc cpp/*.cpp)
add_library (visitHeader SHARED ${cppSrc})
include_directories (${CLANG_C_INCLUDE_DIR} ${LUA_INCLUDE_DIR})
target_link_libraries (visitHeader ${CLANG_LIBRARY} ${LUA_LIBRARIES})
set_target_properties (visitHeader PROPERTIES
	PREFIX ""
	CXX_STANDARD 11
	LIBRARY_OUTPUT_DIRECTORY ${CMAKE_PROJECT_NAME})


# Copy Lua files
set (luaSrc init.lua info.lua generate.lua visitor.lua note.lua find_file.lua)
file (COPY ${luaSrc} DESTINATION ${CMAKE_PROJECT_NAME})
file (COPY main.lua DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

# Templates
if (NOT TEMPLATE_PATH_PREFIX)
	if (WIN32)
		message (SEND_ERROR "No template path is configured for Windows")
	else ()
		set (TEMPLATE_PATH_PREFIX ${CMAKE_INSTALL_PREFIX}/share)
	endif ()
endif ()
set (TEMPLATE_PATH ${TEMPLATE_PATH_PREFIX}/${CMAKE_PROJECT_NAME}/templates)

set (TEMPLATES_LUA "${CMAKE_PROJECT_NAME}/templates.lua")
configure_file (templates.lua.in ${TEMPLATES_LUA} @ONLY)
file (GLOB templateSrc templates/*.molde)
file (COPY ${templateSrc} DESTINATION ${CMAKE_PROJECT_NAME}/templates)

##  Install  ##
set (LUA_VER "${LUA_VERSION_MAJOR}.${LUA_VERSION_MINOR}")

# Variables expected from Luarocks, set if not present
# TODO: use the right path on Windows (using Luarocks is preferred anyway, so no much worries here)
if (NOT LIBDIR)
	set (LIBDIR lib/lua/${LUA_VER})
endif ()
if (NOT LUADIR)
	set (LUADIR share/lua/${LUA_VER})
endif ()
if (NOT BINDIR)
	set (BINDIR bin)
endif ()

install (TARGETS visitHeader
	LIBRARY DESTINATION "${LIBDIR}/${CMAKE_PROJECT_NAME}")
install (PROGRAMS main.lua RENAME inclua
	DESTINATION ${BINDIR})
install (FILES ${luaSrc} "${CMAKE_CURRENT_BINARY_DIR}/${TEMPLATES_LUA}"
	DESTINATION "${LUADIR}/${CMAKE_PROJECT_NAME}")
install (FILES ${templateSrc}
	DESTINATION ${TEMPLATE_PATH})

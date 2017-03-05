file (GLOB cppSrc cpp/*.cpp)
add_library (visitor SHARED ${cppSrc})
target_include_directories (visitor PUBLIC ${CLANG_C_INCLUDE_DIR} ${LUA_INCLUDE_DIR})
target_link_libraries (visitor ${CLANG_LIBRARY} ${LUA_LIBRARIES})
set_target_properties (visitor PROPERTIES
	PREFIX ""
	CXX_STANDARD 11
	LIBRARY_OUTPUT_DIRECTORY ${CMAKE_PROJECT_NAME})


# Copy Lua files
file (GLOB luaSrc *.lua)
file (COPY ${luaSrc} DESTINATION ${CMAKE_PROJECT_NAME})

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

install (TARGETS visitor
	LIBRARY DESTINATION ${LIBDIR}/${CMAKE_PROJECT_NAME})
install (FILES ${luaSrc}
	DESTINATION ${LUADIR}/${CMAKE_PROJECT_NAME})

#!/bin/sh

inclua clang.h -m clang -n clang_ -n CX -i clang-c -d extras.yml > clang.lua
sed -i '
# LuaJIT does not recognize time_t by default
s/time_t/unsigned long/
# For some reason, clang_CompileCommand_getNumMappedSources is not defined in my installation
/clang_CompileCommand_getNumMapp/d
' clang.lua 

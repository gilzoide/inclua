// clang couldn't give me a decent declaration for `time_t` that LuaJIT understood. This might not work on every system
#define time_t unsigned long

#include <clang-c/BuildSystem.h>
#include <clang-c/CXCompilationDatabase.h>
#include <clang-c/CXErrorCode.h>
#include <clang-c/CXString.h>
#include <clang-c/Documentation.h>
#include <clang-c/FatalErrorHandler.h>
#include <clang-c/Index.h>

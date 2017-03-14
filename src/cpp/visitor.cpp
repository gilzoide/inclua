/* Copyright 2016-2017 Gil Barbosa Reis <gilzoide@gmail.com>
 * This file is part of Inclua.
 *
 * Inclua is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Inclua is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Inclua.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "lua.hpp"
#include "clang-c/Index.h"

#include "visitData.hpp"
#include "headerInfo.hpp"
#include "clString.hpp"
#include "luarray.hpp"

#include <iostream>
#include <vector>
#include <cstring>

CXChildVisitResult visitor(CXCursor cursor, CXCursor, visitData *data) {  
	// get the source location...
	CXSourceLocation location = clang_getCursorLocation(cursor);
	CXFile file;
	unsigned line;
	unsigned column;
	clang_getFileLocation(location, &file, &line, &column, nullptr);
	clString fileName = clang_getFileName(file);

	// ...and only get information if it's the required header
	if(!strcmp(fileName, data->headerName)) {
		CXCursorKind kind = clang_getCursorKind(cursor);
		clString kindName = clang_getCursorKindSpelling(kind);

		switch(kind) {
			case CXCursor_FunctionDecl: handleFunction(data, cursor); break;
			// case CXCursor_CXXMethod:
			case CXCursor_StructDecl:
			case CXCursor_UnionDecl:
				handleRecord(data, cursor);
				break;

			case CXCursor_EnumDecl: handleEnum(data, cursor); break;
			case CXCursor_EnumConstantDecl: handleEnumConstant(data, cursor); break;
			case CXCursor_TypedefDecl: handleTypedef(data, cursor); break;

			// default:
				// std::cout << "Não sei isso: " << kindName << '(' << cursorName << ')'<< std::endl;
		}
	}

	return CXChildVisit_Recurse;
}

/**
 * Visit a header, storing the results in a Visitor.
 *
 * @warning Don't ever use this function with a non-Visitor table,
 * as some methods are expected to be there.
 */
int visitHeader(lua_State *L) {
	// parameters from Lua
	luaL_checktype(L, 1, LUA_TTABLE);
	const char *headerName = luaL_checkstring(L, 2);
	vector<const char *> args = getStringArray(L, 3);

	auto idx = clang_createIndex(1, 1);
	auto tu = clang_parseTranslationUnit(idx, headerName, args.data(),
			args.size(), NULL, 0, CXTranslationUnit_SkipFunctionBodies);
	if(!tu) {
		return 0;
	}
	visitData data(L, headerName);
	clang_visitChildren(clang_getTranslationUnitCursor(tu),
			(CXCursorVisitor) visitor, &data);

	clang_disposeTranslationUnit(tu);
	clang_disposeIndex(idx);
	return 1;
}

extern "C" {
	int luaopen_inclua_visitHeader(lua_State *L) {  
		// Type memoization table
		lua_newtable(L);
		lua_setfield(L, LUA_REGISTRYINDEX, INCLUA_KNOWN_TYPES);

		lua_pushcfunction(L, visitHeader);
		return 1;
	}
}


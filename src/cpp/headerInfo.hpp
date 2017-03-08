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

#pragma once

#include "visitData.hpp"
#include "clString.hpp"
#include "clType.hpp"

#include <sstream>
#include <regex>

using namespace std;

/// Push the Visitor and the desired method
void pushMethod(visitData *data, const char *name) {
	lua_State *L = data->L;
	lua_getfield(L, 1, name);
	lua_pushvalue(L, 1);
}

/// Get Cursor spelling, filling blank with `anonymous_at_<file>_<line>_<col>`
string getCursorName(CXCursor cursor) {
	clString spelling = clang_getCursorDisplayName(cursor);
	const char *cursorName = spelling;
	if(*cursorName) {
		return cursorName;
	}
	// Anonymous
	else {
		CXSourceLocation location = clang_getCursorLocation(cursor);
		CXFile file;
		unsigned line;
		unsigned column;
		clang_getFileLocation(location, &file, &line, &column, nullptr);
		clString fileName = clang_getFileName(file);
		// replace non-word chars by '_'
		regex anon_regex("\\W");

		ostringstream os;
		os << "anonymous_at_" << regex_replace((const char *) fileName, anon_regex, "_")
				<< '_' << line << '_' << column;
		return os.str();
	}
}

void handleTypedef(visitData *data, CXCursor cursor) {
	clString alias = clang_getCursorDisplayName(cursor);
	CXType underlying = clang_getTypedefDeclUnderlyingType(cursor);
	auto underlying_hash = clang_hashCursor(clang_getTypeDeclaration(underlying));

	lua_State *L = data->L;
	pushMethod(data, "handleTypedef");
	lua_pushstring(L, alias);
	lua_pushinteger(L, underlying_hash);
	lua_call(L, 3, 0);
}

void handleEnum(visitData *data, CXCursor cursor) {
	auto name = getCursorName(cursor);
	auto cursor_hash = clang_hashCursor(cursor);

	lua_State *L = data->L;
	pushMethod(data, "handleEnum");
	lua_pushinteger(L, cursor_hash);
	lua_pushstring(L, name.data());
	lua_call(L, 3, 0);
}

void handleEnumConstant(visitData *data, CXCursor cursor) {
	clString name = clang_getCursorDisplayName(cursor);
	auto cursor_hash = clang_hashCursor(clang_getCursorSemanticParent(cursor));
	auto value = clang_getEnumConstantDeclValue(cursor);

	lua_State *L = data->L;
	pushMethod(data, "handleEnumConstant");
	lua_pushinteger(L, cursor_hash);
	lua_pushstring(L, name);
	lua_pushinteger(L, value);
	lua_call(L, 4, 0);
}


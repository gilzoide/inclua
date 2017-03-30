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

#include "headerInfo.hpp"

#include <sstream>
#include <regex>

using namespace std;

/// Push the Visitor and the desired method
void pushMethod(visitData *data, const char *name) {
	lua_State *L = data->L;
	lua_getfield(L, 1, name);
	lua_pushvalue(L, 1);
}

/// Get Cursor spelling, filling blank with the Type spelling
string getCursorName(CXCursor cursor) {
	clString spelling = clang_getCursorSpelling(cursor);
	const char *cursorName = spelling;
	if(cursorName[0] != '\0') {
		return cursorName;
	}
	// Anonymous
	else {
		return finalSpelling(clang_getCursorType(cursor));
	}
}

void handleTypedef(visitData *data, CXCursor cursor) {
	clString alias = clang_getCursorSpelling(cursor);
	CXType underlying = clang_getTypedefDeclUnderlyingType(cursor);
	auto underlying_hash = clang_hashCursor(clang_getTypeDeclaration(underlying));

	lua_State *L = data->L;
	pushMethod(data, "__handleTypedef");
	lua_pushstring(L, alias);
	lua_pushinteger(L, underlying_hash);
	lua_call(L, 3, 0);
}

void handleEnum(visitData *data, CXCursor cursor) {
	auto cursor_hash = clang_hashCursor(cursor);
	auto type = clang_getCursorType(cursor);

	lua_State *L = data->L;
	pushMethod(data, "__handleEnum");
	lua_pushinteger(L, cursor_hash);
	pushType(L, type);
	lua_call(L, 3, 0);
}

void handleEnumConstant(visitData *data, CXCursor cursor) {
	clString name = clang_getCursorSpelling(cursor);
	auto cursor_hash = clang_hashCursor(clang_getCursorSemanticParent(cursor));
	auto value = clang_getEnumConstantDeclValue(cursor);

	lua_State *L = data->L;
	pushMethod(data, "__handleEnumConstant");
	lua_pushinteger(L, cursor_hash);
	lua_pushstring(L, name);
	lua_pushinteger(L, value);
	lua_call(L, 4, 0);
}

void handleFunction(visitData *data, CXCursor cursor) {
	clString name = clang_getCursorSpelling(cursor);
	auto type = clang_getCursorType(cursor);

	lua_State *L = data->L;
	pushMethod(data, "__handleFunction");
	lua_pushstring(L, name);
	pushType(L, type);
	lua_call(L, 3, 0);
}

void handleRecord(visitData *data, CXCursor cursor) {
	auto type = clang_getCursorType(cursor);

	lua_State *L = data->L;
	pushMethod(data, "__handleRecord");
	pushType(L, type);
	lua_call(L, 2, 0);
}

void handleVar(visitData *data, CXCursor cursor) {
	clString name = clang_getCursorSpelling(cursor);
	auto type = clang_getCursorType(cursor);

	lua_State *L = data->L;
	pushMethod(data, "__handleVar");
	lua_pushstring(L, name);
	pushType(L, type);
	lua_call(L, 3, 0);
}


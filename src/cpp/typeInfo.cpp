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

#include "typeInfo.hpp"

#include <regex>

/* Custom data for `fieldVisitor` */
struct _fieldData {
	lua_State *L;
	int i {1};
	_fieldData(lua_State *L) : L(L) {}
};

enum CXVisitorResult fieldVisitor(CXCursor cursor, _fieldData *data) {
	clString name = clang_getCursorSpelling(cursor);
	CXType type = clang_getCursorType(cursor);

	lua_State *L = data->L;
	lua_newtable(L);

	lua_pushstring(L, name);
	lua_seti(L, -2, 1);
	pushType(L, type);
	lua_seti(L, -2, 2);

	lua_seti(L, -2, data->i);

	data->i++;

	return CXVisit_Continue;
}

string finalSpelling(CXType type) {
	clType ty(type);
	string spelling;


	const regex anonymous_re(R"ANON((\S+) .*\(anonymous.*at (.+)\))ANON");
	cmatch match;

	if(!regex_match((const char *) ty, match, anonymous_re)) {
		spelling = ty;
	}
	else {
		const regex c_id("\\W");
		spelling = match[1].str() + " anonymous_at_";
		regex_replace(back_inserter(spelling), match[2].first, match[2].second, c_id, "_");
	}

	return move(spelling);
}

void pushType(lua_State *L, CXType type) {
	if(type.kind == CXType_Invalid) {
		throw "Invalid CXType!";
	}
	// Canonicalize Typedefs
	type = clang_getCanonicalType(type);

	clType ty(type);
	auto spelling_str = finalSpelling(type);
	const char *spelling = spelling_str.data();

	// Type memoization
	lua_getfield(L, LUA_REGISTRYINDEX, INCLUA_KNOWN_TYPES);
	if(lua_getfield(L, -1, spelling) == LUA_TNIL) {
		lua_pop(L, 1);

		lua_newtable(L);
		lua_pushstring(L, spelling);
		lua_setfield(L, -2, "name");
		switch(type.kind) {
			case CXType_Void:
				lua_pushliteral(L, "void");
				lua_setfield(L, -2, "kind");
				break;

			case CXType_ConstantArray:
			case CXType_IncompleteArray:
			case CXType_VariableArray: {
					lua_pushliteral(L, "array");
					lua_setfield(L, -2, "kind");
					CXType element_type = clang_getArrayElementType(type);
					pushType(L, type);
					lua_setfield(L, -2, "element_type");
					auto size = clang_getArraySize(type);
					if(size != -1) {
						lua_pushinteger(L, size);
						lua_setfield(L, -2, "size");
					}
				}
				break;

			case CXType_Pointer: {
					CXType element_type = clang_getPointeeType(type);
					lua_pushstring(L, element_type.kind != CXType_FunctionNoProto
						 && element_type.kind != CXType_FunctionProto
						 && element_type.kind != CXType_Unexposed ?
						 "pointer" : "function_pointer");
					lua_setfield(L, -2, "kind");
					pushType(L, element_type);
					lua_setfield(L, -2, "element_type");
				}
				break;

			case CXType_FunctionProto:
			case CXType_FunctionNoProto:
				lua_pushboolean(L, clang_isFunctionTypeVariadic(type));
				lua_setfield(L, -2, "variadic");
				pushType(L, clang_getResultType(type));
				lua_setfield(L, -2, "result_type");
				// arguments
				lua_newtable(L);
				for(int i = 0; i < clang_getNumArgTypes(type); i++) {
					pushType(L, clang_getArgType(type, i));
					lua_seti(L, -2, i + 1);
				}
				lua_setfield(L, -2, "arguments");
				break;

			case CXType_Record:
			case CXType_Elaborated:
				lua_pushliteral(L, "record");
				lua_setfield(L, -2, "kind");
				lua_pushinteger(L, ty.get_hash());
				lua_setfield(L, -2, "hash");
				lua_newtable(L);
				{
					_fieldData data(L);
					clang_Type_visitFields(type, (CXFieldVisitor) fieldVisitor, &data);
					lua_setfield(L, -2, "fields");
				}
				break;

			case CXType_Enum:
				lua_pushliteral(L, "enum");
				lua_setfield(L, -2, "kind");
				break;

			default:
				lua_pushliteral(L, "simple");
				lua_setfield(L, -2, "kind");
				break;
		}
		// register type in Registry[INCLUA_KNOWN_TYPES]
		lua_pushvalue(L, -1);
		lua_setfield(L, -3, spelling);
	}
	// pop Registry[INCLUA_KNOWN_TYPES]
	lua_rotate(L, -2, 1);
	lua_pop(L, 1);
}


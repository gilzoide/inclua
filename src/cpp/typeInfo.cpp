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

void pushType(lua_State *L, CXType type) {
	if(type.kind == CXType_Invalid) {
		throw "Invalid CXType!";
	}
	clType ty(type);
	
	lua_newtable(L);
	lua_pushstring(L, ty);
	lua_setfield(L, -2, "spelling");
	switch(type.kind) {
		case CXType_Void:
			lua_pushliteral(L, "void");
			lua_setfield(L, -2, "kind");
			break;

		case CXType_Pointer:
			CXType element_type = clang_getPointeeType(type);
			lua_pushstring(L, element_type.kind != CXType_FunctionNoProto
					&& element_type.kind != CXType_FunctionProto ?
					"function_pointer" : "pointer");
			lua_setfield(L, -2, "kind");
			break;
	}
}


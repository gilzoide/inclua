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

#include "visitor.hpp"
#include "luarray.hpp"

int lua_visitHeader (lua_State *L) {
	const char *headerName = luaL_checkstring (L, 1);
	vector<const char *> args = getStringArray (L, 2);
	auto ret = visitHeader (headerName, args);
	lua_pushinteger (L, ret);
	return 1;
}


const luaL_Reg functions[] = {
	{ "visitHeader", lua_visitHeader },
	{ NULL, NULL },
};

extern "C" {
	int luaopen_inclua_visitor (lua_State *L) {  
		luaL_newlib (L, functions);
		return 1;
	}
}


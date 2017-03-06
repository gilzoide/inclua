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

#include "lua.hpp"
#include <vector>

using namespace std;

/// Get a string vector from Lua
vector<const char *> getStringArray (lua_State *L, int arg) {
	vector<const char *> ret;
	if (!lua_isnoneornil (L, arg)) {
		int len = luaL_len (L, arg);
		arg = lua_absindex (L, arg);
		for (int i = 1; i <= len; i++) {
			lua_geti (L, arg, i);
			ret.push_back (luaL_checkstring (L, -1));
		}
		lua_pop (L, len);
	}
	return move (ret);
}


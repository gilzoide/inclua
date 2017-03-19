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

#include "clType.hpp"

#include <string>
using namespace std;

#define INCLUA_KNOWN_TYPES "INCLUA_KNOWN_TYPES"

/**
 * Push a table containing information about a CXType.
 *
 * type = {
 *     kind = ['void' | 'simple' | 'pointer' | 'array' | 'record' | 'function_pointer'],
 *     spelling = <CXType.spelling>,
 *     (pointer and array) element_type = <type of an element>,
 *     (array) size = <int with size if specified, nil otherwise>,
 *     (record) fields = <table with fields, name - type pairs>,
 *     (function) result_type = <the return type>,
 *     (function) arguments = <table with argument types>,
 *     (function) variadic = <bool: is function variadic?>
 * }
 */
void pushType(lua_State *L, CXType type);

/**
 * Get spelling, fixing when it is anonymous.
 *
 * If anonymous, get a name based on Type location on source code.
 */
string finalSpelling(CXType type);


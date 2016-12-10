/* Copyright 2016 Gil Barbosa Reis <gilzoide@gmail.com>
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

#include <lua.hpp>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <type_traits>

////////////////////////////////////////////////////////////////////////////////
//  Native types
////////////////////////////////////////////////////////////////////////////////
template<typename T> void inclua_push (lua_State *L, T val) {
	typedef typename std::remove_cv<T>::type noCV;
	static_assert (!std::is_same<T, noCV>::value, "Type not yet registered in inclua_push");
	inclua_push<noCV> (L, val);
}

template<> void inclua_push (lua_State *L, bool b) {
	lua_pushboolean (L, b);
}

template<> void inclua_push (lua_State *L, char c) {
	lua_pushlstring (L, &c, sizeof (char));
}

template<> void inclua_push (lua_State *L, int8_t i) {
	lua_pushinteger (L, i);
}
template<> void inclua_push (lua_State *L, int16_t i) {
	lua_pushinteger (L, i);
}
template<> void inclua_push (lua_State *L, int32_t i) {
	lua_pushinteger (L, i);
}
template<> void inclua_push (lua_State *L, int64_t i) {
	lua_pushinteger (L, i);
}
template<> void inclua_push (lua_State *L, long long int i) {
	lua_pushinteger (L, i);
}
template<> void inclua_push (lua_State *L, uint8_t i) {
	lua_pushinteger (L, i);
}
template<> void inclua_push (lua_State *L, uint16_t i) {
	lua_pushinteger (L, i);
}
template<> void inclua_push (lua_State *L, uint32_t i) {
	lua_pushinteger (L, i);
}
template<> void inclua_push (lua_State *L, uint64_t i) {
	lua_pushinteger (L, i);
}
template<> void inclua_push (lua_State *L, unsigned long long int i) {
	lua_pushinteger (L, i);
}

template<> void inclua_push (lua_State *L, float flt) {
	lua_pushnumber (L, flt);
}
template<> void inclua_push (lua_State *L, double flt) {
	lua_pushnumber (L, flt);
}
template<> void inclua_push (lua_State *L, long double flt) {
	lua_pushnumber (L, flt);
}

template<> void inclua_push (lua_State *L, const char *str) {
	lua_pushstring (L, str);
}
template<> void inclua_push (lua_State *L, char *str) {
	lua_pushstring (L, str);
}


template<typename T> T inclua_check (lua_State *L, int arg) {
	typedef typename std::remove_cv<T>::type noCV;
	return inclua_check<noCV> (L, arg);
}

template<> bool inclua_check (lua_State *L, int arg) {
	return lua_toboolean (L, arg);
}

template<> char inclua_check (lua_State *L, int arg) {
	return *luaL_checkstring (L, arg);
}

template<> int8_t inclua_check (lua_State *L, int arg) {
	return luaL_checkinteger (L, arg);
}
template<> int16_t inclua_check (lua_State *L, int arg) {
	return luaL_checkinteger (L, arg);
}
template<> int32_t inclua_check (lua_State *L, int arg) {
	return luaL_checkinteger (L, arg);
}
template<> int64_t inclua_check (lua_State *L, int arg) {
	return luaL_checkinteger (L, arg);
}
template<> long long int inclua_check (lua_State *L, int arg) {
	return luaL_checkinteger (L, arg);
}
template<> uint8_t inclua_check (lua_State *L, int arg) {
	return luaL_checkinteger (L, arg);
}
template<> uint16_t inclua_check (lua_State *L, int arg) {
	return luaL_checkinteger (L, arg);
}
template<> uint32_t inclua_check (lua_State *L, int arg) {
	return luaL_checkinteger (L, arg);
}
template<> uint64_t inclua_check (lua_State *L, int arg) {
	return luaL_checkinteger (L, arg);
}
template<> unsigned long long int inclua_check (lua_State *L, int arg) {
	return luaL_checkinteger (L, arg);
}

template<> float inclua_check (lua_State *L, int arg) {
	return luaL_checknumber (L, arg);
}
template<> double inclua_check (lua_State *L, int arg) {
	return luaL_checknumber (L, arg);
}
template<> long double inclua_check (lua_State *L, int arg) {
	return luaL_checknumber (L, arg);
}

template<> const char *inclua_check (lua_State *L, int arg) {
	return luaL_checkstring (L, arg);
}

////////////////////////////////////////////////////////////////////////////////
//  Records: Structs/Unions
////////////////////////////////////////////////////////////////////////////////
#define INCLUA_PUSH(record_name) \
	template<> void inclua_push (lua_State *L, record_name *ptr) { \
		if (ptr) { \
			lua_pushlightuserdata (L, ptr); \
			luaL_setmetatable (L, #record_name); \
		} \
		else { \
			lua_pushnil (L); \
		} \
	}

#define INCLUA_PUSH_NON_OPAQUE(record_name) \
	template<> void inclua_push (lua_State *L, record_name & obj) { \
		lua_pushlightuserdata (L, &obj); \
		luaL_setmetatable (L, #record_name); \
	}

#define INCLUA_CHECK(record_name) \
	template<> record_name *inclua_check (lua_State *L, int arg) { \
		return lua_isnoneornil (L, arg) ? NULL : (record_name *) luaL_checkudata (L, arg, #record_name); \
	}

#define INCLUA_CHECK_NON_OPAQUE(record_name) \
	template<> record_name inclua_check (lua_State *L, int arg) { \
		return *((record_name *) luaL_checkudata (L, arg, #record_name)); \
	}

////////////////////////////////////////////////////////////////////////////////
//  Enums
////////////////////////////////////////////////////////////////////////////////
#define INCLUA_PUSH_ENUM(enum_name) \
	template<> void inclua_push (lua_State *L, enum_name value) { \
		inclua_push<int> (L, value); \
	}

#define INCLUA_CHECK_ENUM(enum_name) \
	template<> enum_name inclua_check (lua_State *L, int arg) { \
		return (enum_name) inclua_check<int> (L, arg); \
	}

////////////////////////////////////////////////////////////////////////////////
//  Array types
////////////////////////////////////////////////////////////////////////////////

template<typename T, typename = std::enable_if<std::is_pointer<T>::value>>
void inclua_push_array (lua_State *L, T arr, size_t size) {
	lua_newtable (L);
	for (int i = 0; i < size; i++) {
		inclua_push (L, arr[i]);
		lua_seti (L, -2, i + 1);
	}
}
template<typename T, typename = std::enable_if<std::is_pointer<T>::value>, typename... Sizes>
void inclua_push_array (lua_State *L, T arr, size_t size, Sizes... tail) {
	lua_newtable (L);
	for (int i = 0; i < size; i++) {
		inclua_push_array (L, arr[i], tail...);
		lua_seti (L, -2, i + 1);
	}
}
template<>
void inclua_push_array (lua_State *L, char *arr, size_t size) {
	// char array? Ah, string it is!
	lua_pushlstring (L, arr, size);
}


#define remove_cv_from_ptr(T) typename std::remove_cv<typename std::remove_pointer<T>::type>::type
template<typename T, typename = std::enable_if<std::is_pointer<T>::value>>
T inclua_check_array (lua_State *L, int arg, size_t * size) {
	typedef remove_cv_from_ptr(T) pointeeType;

	int len = luaL_len (L, arg);
	luaL_argcheck (L, len > 0, arg, "Array length should be a positive integer");
	if (size) {
		*size = len;
	}
	pointeeType * ret = new pointeeType [len];
	arg = lua_absindex (L, arg);
	for (int i = 0; i < len; i++) {
		lua_geti (L, arg, i + 1);
		ret[i] = inclua_check<pointeeType> (L, -1);
	}
	lua_pop (L, len);
	return ret;
}
template<typename T, typename = std::enable_if<std::is_pointer<T>::value>, typename... Sizes>
T inclua_check_array (lua_State *L, int arg, size_t * size, Sizes... tail) {
	typedef remove_cv_from_ptr(T) pointeeType;

	int len = luaL_len (L, arg);
	luaL_argcheck (L, len > 0, arg, "Array length should be a positive integer");
	if (size) {
		*size = len;
	}
	pointeeType * ret = new pointeeType [len];
	arg = lua_absindex (L, arg);
	for (int i = 0; i < len; i++) {
		lua_geti (L, arg, i + 1);
		ret[i] = inclua_check_array<pointeeType> (L, -1, tail...);
	}
	lua_pop (L, len);
	return ret;
}
template<>
const char * inclua_check_array (lua_State *L, int arg, size_t * size) {
	// char array? Ah, string it is!
	return luaL_checklstring (L, arg, size);
}


template<typename T, typename = std::enable_if<std::is_pointer<T>::value>>
T inclua_new_array (size_t size) {
	typedef remove_cv_from_ptr(T) pointeeType;
	return new pointeeType [size];
}
template<typename T, typename = std::enable_if<std::is_pointer<T>::value>, typename... Sizes>
T inclua_new_array (size_t size, Sizes... tail) {
	typedef remove_cv_from_ptr(T) pointeeType;
	auto ret = new pointeeType [size];
	for (size_t i = 0; i < size; i++) {
		ret[i] = inclua_new_array<pointeeType> (tail...);
	}
	return ret;
}


template<typename T, typename = std::enable_if<std::is_pointer<T>::value>>
void inclua_delete_array (T arr, size_t size) {
	delete[] arr;
}
template<typename T, typename = std::enable_if<std::is_pointer<T>::value>, typename... Sizes>
void inclua_delete_array (T arr, size_t size, Sizes... tail) {
	for (size_t i = 0; i < size; i++) {
		inclua_delete_array (arr[i], tail...);
	}
	delete[] arr;
}

template<>
void inclua_delete_array (const char * arr, size_t size) {
	// in Lua, the strings from luaL_checkstring are internal, so no need to delete'em
}

#undef remove_cv_from_ptr

#include <lua.hpp>
#include <cstring>
#include <cstdint>
#include <type_traits>

////////////////////////////////////////////////////////////////////////////////
//  Native types
////////////////////////////////////////////////////////////////////////////////
template<typename T> void inclua_push (lua_State *, T);

template<> void inclua_push (lua_State *L, bool b) {
	lua_pushboolean (L, b);
}

template<> void inclua_push (lua_State *L, char c) {
	lua_pushinteger (L, c);
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

template<typename T> void inclua_push_array (lua_State *L, T *arr, size_t size) {
	lua_newtable (L);
	for (int i = 0; i < size; i++) {
		inclua_push (L, arr[i]);
		lua_seti (L, -2, i + 1);
	}
}


template<typename T> T inclua_check (lua_State *, int);

template<> char inclua_check (lua_State *L, int arg) {
	return luaL_checkinteger (L, arg);
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
	} \
	template<> void inclua_push (lua_State *L, record_name & obj) { \
		lua_pushlightuserdata (L, &obj); \
		luaL_setmetatable (L, #record_name); \
	}

#define INCLUA_CHECK(record_name) \
	template<> record_name *inclua_check (lua_State *L, int arg) { \
		return lua_isnoneornil (L, arg) ? NULL : (record_name *) luaL_checkudata (L, arg, #record_name); \
	} \
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

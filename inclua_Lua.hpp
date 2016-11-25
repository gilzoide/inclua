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
//  Structs
////////////////////////////////////////////////////////////////////////////////
#define INCLUA_PUSH(struct_name) \
	template<> void inclua_push (lua_State *L, struct_name *ptr) { \
		if (ptr) { \
			lua_pushlightuserdata (L, ptr); \
			luaL_setmetatable (L, #struct_name); \
		} \
		else { \
			lua_pushnil (L); \
		} \
	} \
	template<> void inclua_push (lua_State *L, struct_name & obj) { \
		lua_pushlightuserdata (L, &obj); \
		luaL_setmetatable (L, #struct_name); \
	}

#define INCLUA_CHECK(struct_name) \
	template<> struct_name *inclua_check (lua_State *L, int arg) { \
		return lua_isnoneornil (L, arg) ? NULL : (struct_name *) luaL_checkudata (L, arg, #struct_name); \
	} \
	template<> struct_name inclua_check (lua_State *L, int arg) { \
		return *((struct_name *) luaL_checkudata (L, arg, #struct_name)); \
	}


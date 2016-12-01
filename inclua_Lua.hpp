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

template<> void inclua_push (lua_State *L, float flt) {
	lua_pushnumber (L, flt);
}
template<> void inclua_push (lua_State *L, double flt) {
	lua_pushnumber (L, flt);
}
template<> void inclua_push (lua_State *L, long double flt) {
	lua_pushnumber (L, flt);
}

template<> void inclua_push (lua_State *L, char *str) {
	lua_pushstring (L, str);
}

template<typename T> void inclua_push_array (lua_State *L, T *arr, size_t size) {
	lua_newtable (L);
	for (int i = 0; i < size; i++) {
		inclua_push (L, arr[i]);
		lua_seti (L, -2, i + 1);
	}
}
template<> void inclua_push_array (lua_State *L, char *arr, size_t size) {
	lua_pushlstring (L, arr, size);
}


template<typename T> T inclua_check (lua_State *L, int arg) {
	typedef typename std::remove_cv<T>::type noCV;
	return inclua_check<noCV> (L, arg);
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

template<typename T, typename Size, typename = std::enable_if<std::is_integral<T>::value>>
T *inclua_check_array (lua_State *L, int arg, Size & size) {
	typedef typename std::remove_cv<T>::type arrType;

	int len = luaL_len (L, arg);
	luaL_argcheck (L, len > 0, arg, "Array length should be a positive integer");
	size = len;
	arrType *ret = new arrType [size];
	for (int i = 0; i < size; i++) {
		lua_geti (L, arg, i + 1);
		ret[i] = inclua_check<T> (L, -1);
	}
	lua_pop (L, size);
	return ret;
}

template<typename T>
T *inclua_check_array_plus (lua_State *L, int arg, T trailing_value) {
	int len = luaL_len (L, arg);
	luaL_argcheck (L, len > 0, arg, "Array length should be a positive integer");
	T *ret = new T [len + 1];
	for (int i = 0; i < len; i++) {
		lua_geti (L, arg, i + 1);
		ret[i] = inclua_check<T> (L, -1);
	}
	ret[len] = trailing_value;
	lua_pop (L, len);
	return ret;
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

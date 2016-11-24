// Tem que virar
#include "inclua_Lua.hpp"
#include "teste.h"

////////////////////////////////////////////////////////////////////////////////
//  Struct Oi
////////////////////////////////////////////////////////////////////////////////
INCLUA_PUSH (Oi);
INCLUA_PUSH_NEW (Oi);
INCLUA_CHECK (Oi);

template<typename = Oi> int inclua_index (lua_State *L) {
	Oi *obj = inclua_check<Oi *> (L, 1);
	const char *key = inclua_check<const char *> (L, 2);

	if (!strcmp (key, "a")) inclua_push (L, obj->a);
	else if (!strcmp (key, "b")) inclua_push (L, obj->b);
	else return luaL_error (L, "struct Oi doesn't have a \"%s\" field", key);

	return 1;
}

int newindex_Oi (lua_State *L) {
	Oi *obj = inclua_check<Oi *> (L, 1);
	const char *key = inclua_check<const char *> (L, 2);

	if (!strcmp (key, "a")) obj->a = inclua_check<int> (L, 3);
	else if (!strcmp (key, "b")) obj->b = inclua_check<int> (L, 3);
	else return luaL_error (L, "struct Oi doesn't have a \"%s\" field", key);

	return 0;
}

void register_struct_Oi (lua_State *L) {
	int (*call_Oi) (lua_State *) = inclua_push_new<Oi>;
	const luaL_Reg Oi_metatable[] = {
		{ "__index", inclua_index<Oi> },
		{ "__newindex", newindex_Oi },
		{ "__call", call_Oi },
		{ NULL, NULL },
	};

	luaL_newmetatable (L, "Oi");
	luaL_setfuncs (L, Oi_metatable, 0);
	lua_pushliteral (L, "struct Oi");
	lua_setfield (L, -2, "__metatable");
	luaL_setmetatable (L, "Oi");
}

////////////////////////////////////////////////////////////////////////////////
//  Struct Outra
////////////////////////////////////////////////////////////////////////////////
INCLUA_PUSH (Outra);
INCLUA_CHECK (Outra);

void inclua_register_Outra (lua_State *L) {
	luaL_newmetatable (L, "Outra");
	lua_pushliteral (L, "Outra");
	lua_setfield (L, -2, "__metatable");
	luaL_setmetatable (L, "Outra");
}

////////////////////////////////////////////////////////////////////////////////
//  Functions
////////////////////////////////////////////////////////////////////////////////
int wrap_getOi (lua_State *L) {
	Oi *arg1 = inclua_check<Oi *> (L, 1);

	Oi *ret = getOi (arg1);
	inclua_push (L, ret);

	return 1;
}

int wrap_oiMundo (lua_State *L) {
	oiMundo ();
	return 0;
}

int wrap_getSoma (lua_State *L) {
	Oi *arg1 = inclua_check<Oi *> (L, 1);

	int ret = getSoma (arg1);
	inclua_push (L, ret);

	return 1;
}

////////////////////////////////////////////////////////////////////////////////
//  Module init
////////////////////////////////////////////////////////////////////////////////
int luaopen_teste (lua_State *L) {
	const luaL_Reg teste_functions[] = {
		{ "getOi", wrap_getOi },
		{ "oiMundo", wrap_oiMundo },
		{ "getSoma", wrap_getSoma },
		{ NULL, NULL },
	};
	luaL_newlib (L, teste_functions);
	// Struct Oi
	register_struct_Oi (L);
	lua_setfield (L, -2, "Oi");
	// Struct Outra
	inclua_register_Outra (L);
	lua_setfield (L, -2, "Outra");

	return 1;
}

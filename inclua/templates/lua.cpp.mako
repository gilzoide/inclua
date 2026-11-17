<%namespace file="inclua.notice.mako" import="c_notice"/>

<% 
    import re

    lua_module_name = re.sub(r"\W", "_", module_name)
    definitions_by_spelling = {d['spelling']: d
                               for d in definitions
                               if d.get('spelling')}
    def get_def(d):
        return definitions_by_spelling.get(d['spelling'], d)

    all_records = []
    all_functions = []
%>

<%def name="def_record(d)" filter="trim">
    <%def name="def_fields(fields)" filter="trim">
    % for f in fields:
        % if f[1]:
        if (strncmp("${f[1]}", key, size) == 0) {
            inclua_push(L, obj->${f[1]});
            return 1;
        }
        % else:
        ${def_fields(get_def(f[0])['fields'])}
        % endif
    % endfor
    </%def>
<% 
    metatable = d['name']
    spelling = d['spelling']
    fields = d['fields']
    all_records.append(metatable)
%>
INCLUA_PUSH(${spelling})
INCLUA_CHECK(${spelling})
% if fields:
INCLUA_PUSH_NON_OPAQUE(${spelling})
INCLUA_CHECK_NON_OPAQUE(${spelling})

int inclua_push_new_${metatable}(lua_State *L) {
    ${spelling} obj = {};
    inclua_push(L, obj);
    return 1;
}

int inclua_index_${metatable}(lua_State *L) {
    auto obj = inclua_check<${spelling} *>(L, 1);
    size_t size;
    if (const char *key = lua_tolstring(L, 2, &size)) {
        ${def_fields(fields)}
    }
    luaL_getmetatable(L, "${metatable}");
    lua_pushvalue(L, 2);
    lua_gettable(L, -2);
    lua_rotate(L, -2, 1);
    lua_pop(L, 1);
    return 1;
}
% endif
void inclua_register_${metatable}(lua_State *L) {
    if (luaL_newmetatable(L, "${metatable}")) {
    % if fields:
        const luaL_Reg metamethods[] = {
            { "__index", &inclua_index_${metatable} },
            { NULL, NULL },
        };
        inclua_register_functions(L, metamethods);
    % else:
        lua_pushvalue(L, -1);
        lua_setfield(L, -2, "__index");
    % endif
    }
}
</%def>

<%def name="def_function(d)" filter="trim">
    <%def name="call_func()" filter="trim">
        ${d['name']}(${', '.join('arg{}'.format(i) for i in range(len(d['arguments'])))})
    </%def>
<%
    all_functions.append(d['name'])
    return_type = d['return_type']['spelling']
    return_values = ['_result'] if return_type != 'void' else []
%>
int wrap_${d['name']}(lua_State *L) {
    % for argument_type, argument_name in d['arguments']:
    auto arg${loop.index} = inclua_check<${argument_type['spelling']}>(L, ${loop.index});
    % endfor
    % if return_type == 'void':
    ${call_func()}
    % else:
    ${return_type} _result = ${call_func()};
    % endif
    % for name in return_values:
    inclua_push(L, ${name});
    % endfor
    return ${len(return_values)};
}
</%def>

${c_notice()}

/*
 * This code is C++17
 */

#ifndef INCLUA_LUA_HPP
#define INCLUA_LUA_HPP

#include "${header}"
#include "lua.hpp"
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <type_traits>

////////////////////////////////////////////////////////////////////////////////
//  Fundamental types
////////////////////////////////////////////////////////////////////////////////
template<typename T>
void inclua_push(lua_State *L, T val) {
    if constexpr (std::is_function<typename std::remove_pointer<T>::type>::value) {
        // TODO: handle function pointers better
        inclua_push<void *>(L, (void *) val);
    }
    else if constexpr (std::is_array<T>::value) {
        // inclua_push_array(L, val);
    }
    else if constexpr (std::is_integral<T>::value) {
        lua_pushinteger(L, val);
    }
    else if constexpr (std::is_floating_point<T>::value) {
        lua_pushnumber(L, val);
    }
    else {
        typedef typename std::remove_cv<T>::type noCV;
        inclua_push<noCV>(L, val);
    }
}

template<> void inclua_push(lua_State *L, bool b) {
    lua_pushboolean(L, b);
}

template<> void inclua_push(lua_State *L, char c) {
    lua_pushlstring(L, &c, sizeof(char));
}

template<> void inclua_push(lua_State *L, const char *str) {
    if (str) {
        lua_pushstring(L, str);
    }
    else {
        lua_pushnil(L);
    }
}

template<> void inclua_push(lua_State *L, void *ptr) {
    lua_pushlightuserdata(L, ptr);
}
template<> void inclua_push(lua_State *L, const void *ptr) {
    lua_pushlightuserdata(L, (void *) ptr);
}


template<typename T> T inclua_check(lua_State *L, int arg) {
    if constexpr (std::is_function<typename std::remove_pointer<T>::type>::value) {
        // TODO: handle function pointers better
        return inclua_check<void *>(L, arg);
    }
    else if constexpr (std::is_array<T>::value) {
        // inclua_check_array(L, val);
        return nullptr;
    }
    else if constexpr (std::is_integral<T>::value) {
        return luaL_checkinteger(L, arg);
    }
    else if constexpr (std::is_floating_point<T>::value) {
        return luaL_checknumber(L, arg);
    }
    else {
        typedef typename std::remove_cv<T>::type noCV;
        return inclua_check<noCV> (L, arg);
    }
}

template<> bool inclua_check(lua_State *L, int arg) {
    return lua_toboolean(L, arg);
}

template<> char inclua_check(lua_State *L, int arg) {
    const char *str = luaL_checkstring(L, arg);
    return str ? str[0] : 0;
}

template<> const char *inclua_check(lua_State *L, int arg) {
    return luaL_checkstring(L, arg);
}

template<> void *inclua_check(lua_State *L, int arg) {
    return lua_touserdata(L, arg);
}

<%text filter="trim">
////////////////////////////////////////////////////////////////////////////////
//  Records: Structs/Unions
////////////////////////////////////////////////////////////////////////////////
struct inclua_object_t {
    bool is_pointer;
    uint8_t data[0];

    void *get() {
        return is_pointer ? *((void **) data) : (void *) &data;
    }

    template<typename T>
    void set(bool is_pointer, T *data) {
        this->is_pointer = is_pointer;
        if (is_pointer) {
            *((T **) this->data) = data;
        }
        else {
            memcpy(this->data, data, sizeof(T));
        }
    }
};

void inclua_register_functions(lua_State *L, const luaL_Reg *l) {
#if LUA_VERSION_NUM >= 502
    luaL_setfuncs(L, l, 0);
#else
    luaL_register(L, NULL, l);
#endif
}

#define INCLUA_PUSH(record_name) \
    template<> void inclua_push(lua_State *L, record_name *ptr) { \
        if (ptr) { \
            inclua_object_t *lua_obj = (inclua_object_t *) lua_newuserdata(L, sizeof(inclua_object_t) + sizeof(record_name *)); \
            lua_obj->set(true, ptr); \
            luaL_setmetatable(L, #record_name); \
        } \
        else { \
            lua_pushnil(L); \
        } \
    }

#define INCLUA_PUSH_NON_OPAQUE(record_name) \
    template<> void inclua_push(lua_State *L, record_name obj) { \
        inclua_object_t *lua_obj = (inclua_object_t *) lua_newuserdata(L, sizeof(inclua_object_t) + sizeof(record_name *)); \
        lua_obj->set(false, &obj); \
        luaL_setmetatable(L, #record_name); \
    }

#define INCLUA_CHECK(record_name) \
    template<> record_name *inclua_check(lua_State *L, int arg) { \
        if (lua_isnoneornil(L, arg)) { \
            return NULL; \
        } \
        else { \
            inclua_object_t *obj = (inclua_object_t *) luaL_checkudata(L, arg, #record_name); \
            return (record_name *) obj->get(); \
        } \
    }

#define INCLUA_CHECK_NON_OPAQUE(record_name) \
    template<> record_name inclua_check(lua_State *L, int arg) { \
        return *(inclua_check<record_name *>(L, arg)); \
    }

////////////////////////////////////////////////////////////////////////////////
//  Enums
////////////////////////////////////////////////////////////////////////////////
#define INCLUA_PUSH_ENUM(enum_name) \
    template<> void inclua_push(lua_State *L, enum_name value) { \
        typedef typename std::underlying_type<enum_name>::type int_type; \
        inclua_push<int_type>(L, value); \
    }

#define INCLUA_CHECK_ENUM(enum_name) \
    template<> enum_name inclua_check(lua_State *L, int arg) { \
        typedef typename std::underlying_type<enum_name>::type int_type; \
        return (enum_name) inclua_check<int_type>(L, arg); \
    }
</%text>
% for d in definitions:
    % if d['kind'] in ('struct', 'union') and not d.get('anonymous'):
////////////////////////////////////////////////////////////////////////////////
//  ${d['name']}
////////////////////////////////////////////////////////////////////////////////
${def_record(d)}

    % elif d['kind'] == 'function':
${def_function(d)}

    % endif
% endfor

extern "C" int luaopen_${lua_module_name}(lua_State *L) {
    const luaL_Reg functions[] = {
    % for function_name in all_functions:
        { "${function_name}", &wrap_${function_name} },
    % endfor
        { NULL, NULL },
    };
#if LUA_VERSION_NUM >= 502
    luaL_newlib(L, functions);
#else
    lua_newtable(L);
    inclua_register_functions(L, functions);
#endif

% for record_name in all_records:
    inclua_register_${record_name}(L);
    lua_setfield(L, -2, "${record_name}");

% endfor

    return 1;
}

#endif

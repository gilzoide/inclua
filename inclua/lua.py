## Copyright 2016 Gil Barbosa Reis <gilzoide@gmail.com>
# This file is part of Inclua.
#
# Inclua is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Inclua is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Inclua.  If not, see <http://www.gnu.org/licenses/>.

import re
from . import Type, GeneralInfo
from .Generator import Generator
from .Visitor import Visitor
from .Error import IncluaError
from .Note import Note

# First of all, the common inclua stuff, that would be in a header
inclua_hpp = r"""
#ifndef INCLUA_LUA_HPP
#define INCLUA_LUA_HPP

#include "lua.hpp"
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
    if (str) {
        lua_pushstring (L, str);
    }
    else {
        lua_pushnil (L);
    }
}
template<> void inclua_push (lua_State *L, char *str) {
    if (str) {
        lua_pushstring (L, str);
    }
    else {
        lua_pushnil (L);
    }
}

template<> void inclua_push (lua_State *L, void *ptr) {
    lua_pushlightuserdata (L, ptr);
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
    return lua_isnoneornil (L, arg) ? NULL : luaL_checkstring (L, arg);
}

template<> void *inclua_check (lua_State *L, int arg) {
    void *ptr = lua_touserdata (L, arg);
    // if full userdata, do the uservalue trick
    if (lua_type (L, arg) == LUA_TUSERDATA) {
        if (lua_getuservalue (L, arg) != LUA_TBOOLEAN) {
            ptr = *((void **) ptr);
        }
        lua_pop (L, 1);
    }
    return ptr;
}

////////////////////////////////////////////////////////////////////////////////
//  Records: Structs/Unions
////////////////////////////////////////////////////////////////////////////////
#define INCLUA_PUSH(record_name) \
    template<> void inclua_push (lua_State *L, record_name *ptr) { \
        if (ptr) { \
            record_name **block = (record_name **) lua_newuserdata (L, sizeof (void *)); \
            luaL_setmetatable (L, #record_name); \
            *block = ptr; \
        } \
        else { \
            lua_pushnil (L); \
        } \
    }

#define INCLUA_PUSH_NON_OPAQUE(record_name) \
    template<> void inclua_push (lua_State *L, record_name obj) { \
        record_name **block = (record_name **) lua_newuserdata (L, sizeof (void *)); \
        luaL_setmetatable (L, #record_name); \
        *block = &obj; \
    }

#define INCLUA_CHECK(record_name) \
    template<> record_name *inclua_check (lua_State *L, int arg) { \
        if (lua_isnoneornil (L, arg)) { \
            return NULL; \
        } \
        else { \
            record_name *ptr = (record_name *) luaL_checkudata (L, arg, #record_name); \
            if (lua_getuservalue (L, arg) != LUA_TBOOLEAN) { \
                ptr = *((record_name **) ptr); \
            } \
            lua_pop (L, 1); \
            return ptr; \
        } \
    }

#define INCLUA_CHECK_NON_OPAQUE(record_name) \
    template<> record_name inclua_check (lua_State *L, int arg) { \
        return *(inclua_check<record_name *> (L, arg)); \
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
    // check for NULL array
    if (lua_isnoneornil (L, arg)) {
        if (size) {
            *size = 0;
        }
        return NULL;
    }

    int len = luaL_len (L, arg);
    luaL_argcheck (L, len >= 0, arg, "Array length should be a positive integer");
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
    // check for NULL array
    if (lua_isnoneornil (L, arg)) {
        if (size) {
            *size = 0;
        }
        return NULL;
    }

    int len = luaL_len (L, arg);
    luaL_argcheck (L, len >= 0, arg, "Array length should be a positive integer");
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
void inclua_delete_array (T arr) {
    delete[] arr;
}
template<typename T, typename = std::enable_if<std::is_pointer<T>::value>>
void inclua_delete_array (T arr, size_t size) {
    for (size_t i = 0; i < size; i++) {
        inclua_delete_array (arr[i]);
    }
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
void inclua_delete_array (const char * arr) {
    // in Lua, the strings from luaL_checkstring are internal, so no need to delete'em
}

#undef remove_cv_from_ptr
#endif
"""

# Struct/Union bindings templates and generator
record_bindings = r"""////////////////////////////////////////////////////////////////////////////////
//  {record}
////////////////////////////////////////////////////////////////////////////////
{non_opaque}
void inclua_register_{alias} (lua_State *L) {{
    if (luaL_newmetatable (L, "{record}")) {{
        {metamethods}
        lua_pushliteral (L, "{record}");
        lua_setfield (L, -2, "__metatable");
    }}
}}
"""
record_non_opaque_bindings = r"""
int inclua_push_new_{alias} (lua_State *L) {{
    lua_newuserdata (L, sizeof ({record}));
    luaL_setmetatable (L, "{record}");
    // Mark userdata as non-pointer
    lua_pushboolean (L, 1);
    lua_setuservalue (L, -2);
    return 1;
}}

int inclua_index_{alias} (lua_State *L) {{
    {record} *obj = inclua_check<{record} *> (L, 1);
    const char *key = inclua_check<const char *> (L, 2);

    {index_lines}
    else {{
        luaL_getmetatable (L, "{record}");
        lua_getfield (L, -1, key);
        lua_rotate (L, -2, 1);
        lua_pop (L, 1);
    }}
    return 1;
}}

int inclua_new_index_{alias} (lua_State *L) {{
    {record} *obj = inclua_check<{record} *> (L, 1);
    const char *key = inclua_check<const char *> (L, 2);

    {new_index_lines}
    else return luaL_error (L, "{record} doesn't have a \"%s\" field", key);

    return 0;
}}
"""
record_anonymous_non_opaque_bindings = r"""
int inclua_index_{alias} (lua_State *L) {{
    {record} *obj = inclua_check<{record} *> (L, 1);
    const char *key = inclua_check<const char *> (L, 2);

    {index_lines}
    else return luaL_error (L, "{record} doesn't have a \"%s\" field", key);
    return 1;
}}

int inclua_new_index_{alias} (lua_State *L) {{
    {record} *obj = inclua_check<{record} *> (L, 1);
    const char *key = inclua_check<const char *> (L, 2);

    {new_index_lines}
    else return luaL_error (L, "{record} doesn't have a \"%s\" field", key);

    return 0;
}}
"""
record_metamethods_bindings = r"""
        const luaL_Reg metamethods[] = {{
            {{ "__index", inclua_index_{alias} }},
            {{ "__newindex", inclua_new_index_{alias} }},
            {{ "new", inclua_push_new_{alias} }},
            {{ NULL, NULL }},
        }};
        luaL_setfuncs (L, metamethods, 0);
"""
record_anonymous_metamethods_bindings = r"""
        const luaL_Reg metamethods[] = {{
            {{ "__index", inclua_index_{alias} }},
            {{ "__newindex", inclua_new_index_{alias} }},
            {{ NULL, NULL }},
        }};
        luaL_setfuncs (L, metamethods, 0);
"""
record_index_metatable_bindings = r"""
        lua_pushvalue (L, -1);
        lua_setfield (L, -2, "__index");
"""
record_index_bindings = '{0} (!strcmp (key, "{field}")) inclua_push (L, {ref_if_record}obj->{field});'
record_new_index_bindings = '{0} (!strcmp (key, "{field}")) obj->{field} = inclua_check<{type}> (L, 3);'
record_push_check_bindings = r"""// Push/Check {record}
INCLUA_PUSH ({record});
INCLUA_CHECK ({record});"""
record_anonymous_push_bindings = r"""// Push/Check anonymous {record}
{record} {{
    {anon_fields}
}};
INCLUA_PUSH ({record});
INCLUA_CHECK ({record});"""
record_anonymous_field_bindings = r"""{type} {name};"""
record_push_check_non_opaque_bindings = r"""// Push/Check {record}
INCLUA_PUSH ({record});
INCLUA_CHECK ({record});
INCLUA_PUSH_NON_OPAQUE ({record});
INCLUA_CHECK_NON_OPAQUE ({record});"""


def _trim_prefix (s):
    return s.split (' ')[-1]

def _generate_record_index (record):
    return '\n    '.join ([record_index_bindings.format (i == 0 and 'if' or 'else if',
            field = f[0], type = f[1], ref_if_record = f[1].kind == 'record' and 
                    (f[1].is_anonymous () and '({} *) &'.format (f[1]) or '&') or '')
            for i, f in enumerate (record.fields)])
def _generate_record_new_index (record):
    return '\n    '.join ([record_new_index_bindings.format (i == 0 and 'if' or 'else if', field = f[0], type = f[1])
            for i, f in enumerate (record.fields) if not f[1].is_anonymous ()])
def _generate_anon_fields (record):
    return '\n    '.join ([record_anonymous_field_bindings.format (
            type = f[1], name = f[0])
            for f in record.fields])
def _generate_record_push_check (record):
    if record.is_anonymous ():
        return record_anonymous_push_bindings.format (
                record = record,
                anon_fields = _generate_anon_fields (record))
    elif record.num_fields <= 0:
        bindings = record_push_check_bindings
    else:
        bindings = record_push_check_non_opaque_bindings
    return bindings.format (record = record)
def _generate_record (record, notes):
    """Generate record binding functions, taking care if record is opaque (got no fields)"""
    meta = _trim_prefix (str (record))
    if record.is_anonymous ():
        non_opaque = record_anonymous_non_opaque_bindings.format (
                record = record,
                alias = meta,
                index_lines = _generate_record_index (record),
                new_index_lines = _generate_record_new_index (record))
        metamethods = record_anonymous_metamethods_bindings.format (record = record, alias = meta)
    elif record.num_fields == 0 or notes == 'opaque':
        non_opaque, metamethods = '', record_index_metatable_bindings
    else:
        non_opaque = record_non_opaque_bindings.format (
                record = record,
                alias = meta,
                index_lines = _generate_record_index (record),
                new_index_lines = _generate_record_new_index (record))
        metamethods = record_metamethods_bindings.format (record = record, alias = meta)
    return record_bindings.format (
            record = record,
            alias = meta,
            non_opaque = non_opaque,
            metamethods = metamethods)

# Enum bindings templates and generator
enum_wrapper_bindings = r"""
////////////////////////////////////////////////////////////////////////////////
//  enum {alias}
////////////////////////////////////////////////////////////////////////////////
{not_anonymous}
void inclua_register_{alias} (lua_State *L) {{
    {enum_constant_lines}
}}
"""
enum_constant_bindings = r"""inclua_push<int> (L, {const}); lua_setfield (L, -2, "{alias}");"""
enum_not_anonymous_bindings = r"""INCLUA_PUSH_ENUM ({enum});
INCLUA_CHECK_ENUM ({enum});
"""
def _generate_enum (G, enum):
    """Generate enum binding functions, pushing all of it's values to toplevel module,
    or a namespaced table"""
    lines = [enum_constant_bindings.format (const = const, alias = G.final_name (const))
            for const in enum.values.keys ()]
    not_anonymous = str (enum).startswith ('anonymous') and '// Anonymous' or enum_not_anonymous_bindings.format (enum = enum)
    return enum_wrapper_bindings.format (
            enum = enum,
            not_anonymous = not_anonymous,
            alias = enum.alias or enum.symbol.replace ('enum ', ''),
            enum_constant_lines = '\n    '.join (lines))

# Function bindings templates and generator
function_wrapper_bindings = r"""
int wrap_{name} (lua_State *L) {{
    {arguments}
    {call}
    {push_rets}
    {free_stuff}
    return {ret_num};
}}"""
native_function_wrapper_bindings = r"""
int wrap_{name} (lua_State *L) {{
    return {name} (L);
}}"""
function_argument_in_bindings = '{type} arg{i} = inclua_check<{type}> (L, {i_stack});'
function_argument_funcpointer_in_bindings = r"""{ret_type} (*arg{i}) ({arguments});
    if (lua_isnoneornil (L, {i_stack})) {{
        arg{i} = nullptr;
    }}
    else {{
        luaL_checktype (L, {i_stack}, LUA_TFUNCTION);
        lua_pushvalue (L, {i_stack});
        lua_setfield (L, LUA_REGISTRYINDEX, "INCLUA_CALLBACKINDEX_{callback_name}");
        arg{i} = inclua_callback_{callback_name};
    }}"""
function_argument_out_bindings = '{type} arg{i}{init};'
function_argument_size_bindings = '{type} arg{i};'
function_argument_arrayin_bindings = '{type} arg{i} = inclua_check_array<{type}> (L, {i_stack}, {size});'
function_argument_arrayin_until_bindings = '{type} arg{i} = inclua_check_array_plus<{pointee_type}> (L, {i_stack}, {trailing});'
function_argument_arrayout_bindings = '{type} arg{i} = inclua_new_array<{type}> ({sizes});'
function_argname_bindings = 'arg{i}'
function_sizename_bindings = 'size{i}'
function_size_bindings = 'size_t size{i} = {val};'
function_with_ret_bindings = '{type} ret = {call}'
function_push_ret_bindings = 'inclua_push (L, {});'
function_push_ret_array_bindings = 'inclua_push_array (L, {}, {});'
function_call_bindings = '{sym} ({args});'
function_free_bindings = '{} ({});'

callback_bindings = r"""
{ret_type} inclua_callback_{callback_name} ({call_arguments}) {{
    lua_State *L = callback_State;
    lua_getfield (L, LUA_REGISTRYINDEX, "INCLUA_CALLBACKINDEX_{callback_name}");
    {push_arguments}
    lua_call (L, {num_arguments}, {num_rets});
    {maybe_return}
}}"""
callback_return_non_void_bindings = r"""
    {ret_type} ret = inclua_check<{ret_type}> (L, -1);
    return ret;"""
callbacks = []

def _address_of (s):
    return '&{}'.format (s)
def _generate_delete_array_args (arr, sizes):
    return ', '.join ([arr] + sizes[1:])
def _generate_function (func, notes):
    """Generate function bindings, taking care of the notes given, so that everything
    works really well, and makes people want to use your module"""

    # just tail call native functions
    if notes == 'native':
        return native_function_wrapper_bindings.format (name = func)

    notes = notes or ['in'] * func.num_args
    if len (notes) < func.num_args:
        raise IncluaError ("Expected at least {} notes for wrapping '{!s}', but only {} were given".format (func.num_args, func, len (notes)))
    arg_decl = []
    array_decl = []
    frees = []
    arg_call = []
    returns = []
    # process arguments, and their notes
    i_lua_stack = 1
    i_size = 1
    for i, ty, note in zip (range (func.num_args), func.arg_types, notes):
        # don't let user include extra lines of code, so they don't mess things up (users, huh)
        if ';' in note:
            raise IncluaError ("Note shouldn't have ';', no extra code allowed! @ {!r}".format (note))

        info = Note.parse (note)
        if info.kind == 'in':
            argname = function_argname_bindings.format (i = i + 1)
            # function pointer input
            if ty.kind == 'functionpointer':
                callback_name = str (func) + '_' + argname
                arguments = ', '.join (["{type}".format (type = ty)
                        for ty in ty.arg_types])
                call_arguments = ', '.join (["{type} arg{i}".format (i = i + 1, type = ty)
                        for i, ty in enumerate (ty.arg_types)])
                push_arguments = '\n'.join (["inclua_push (L, arg{i});".format (i = i + 1)
                        for i in range (len (ty.arg_types))])
                if ty.ret_type.kind == 'void':
                    maybe_return = 'return;'
                    num_rets = 0
                else:
                    maybe_return = callback_return_non_void_bindings.format (ret_type = ty.ret_type)
                    num_rets = 1
                arg_decl.append (function_argument_funcpointer_in_bindings.format (
                        type = ty, i = i + 1, i_stack = i_lua_stack,
                        callback_name = callback_name,
                        arguments = arguments,
                        ret_type = ty.ret_type))
                callbacks.append (callback_bindings.format (
                        ret_type = ty.ret_type,
                        callback_name = callback_name,
                        call_arguments = call_arguments,
                        num_arguments = len (ty.arg_types),
                        num_rets = num_rets,
                        push_arguments = push_arguments,
                        maybe_return = maybe_return))
            else:
                arg_decl.append (function_argument_in_bindings.format (type = ty, i = i + 1, i_stack = i_lua_stack))
            arg_call.append (argname)
            i_lua_stack += 1
        elif info.kind == 'out':
            arg_decl.append (function_argument_out_bindings.format (
                    type = ty.pointee_type,
                    i = i + 1,
                    init = '' if ty.pointee_type.kind != 'pointer' else ' = nullptr'))
            argname = function_argname_bindings.format (i = i + 1)
            arg_call.append (_address_of (argname))
            returns.append (function_push_ret_bindings.format (argname))
            # always free the memory you alloc
            if info.free:
                frees.append ( (info.free, argname) )
        elif info.kind == 'inout':
            # input
            arg_decl.append (function_argument_in_bindings.format (type = ty.pointee_type, i = i + 1, i_stack = i_lua_stack))
            i_lua_stack += 1
            # and output
            argname = function_argname_bindings.format (i = i + 1)
            arg_call.append (_address_of (argname))
            returns.append (function_push_ret_bindings.format (argname))
            # always free the memory you alloc
            if info.free:
                frees.append ( (info.free, argname) )
        elif info.kind == 'array in':
            array_decl.append (function_argument_arrayin_bindings.format (
                    type = ty,
                    i = i + 1, i_stack = i_lua_stack,
                    size = ', '.join (map (lambda s: s in ['_', 'NULL'] and '(size_t *) NULL' or _address_of (s), info.dims))))
            argname = function_argname_bindings.format (i = i + 1)
            arg_call.append (argname)
            frees.append ( ('inclua_delete_array', ', '.join (map (lambda s: s == '_' and 'NULL' or s, [argname] + info.dims[1:]))) )
            i_lua_stack += 1
        elif info.kind == 'array out':
            argname = function_argname_bindings.format (i = i + 1)
            sizes = ', '.join (info.dims)
            array_decl.append (function_argument_arrayout_bindings.format (
                    type = ty,
                    i = i + 1,
                    sizes = sizes))
            returns.append (function_push_ret_array_bindings.format (argname, sizes))
            arg_call.append (argname)
            frees.append ( ('inclua_delete_array', _generate_delete_array_args (argname, info.dims)) )
        elif info.kind == 'size in':
            arg_decl.append (function_argument_size_bindings.format (type = 'size_t', i = i + 1))
            arg_call.append (function_argname_bindings.format (i = i + 1))
        elif info.kind == 'size out':
            arg_decl.append (function_argument_out_bindings.format (type = ty.pointee_type, i = i + 1, init = ''))
            argname = function_argname_bindings.format (i = i + 1)
            arg_call.append (_address_of (argname))

    _call = function_call_bindings.format (sym = func, args = ', '.join (arg_call))
    # return
    if str (func.ret_type) != 'void':
        # there's a Note for return, see if it's something "out"
        if len (notes) > func.num_args:
            info = Note.parse (notes[func.num_args])
            if info.kind == 'out':
                returns.insert (0, function_push_ret_bindings.format ('ret'))
                if info.free:
                    frees.append ( (info.free, 'ret') )
            elif info.kind == 'array out':
                sizes = ', '.join (info.dims)
                frees.append ( ('inclua_delete_array', _generate_delete_array_args ('ret', info.dims)) )
                returns.insert (0, function_push_ret_array_bindings.format ('ret', sizes))
            else:
                raise IncluaError ("Note for return value should be 'out' or 'array out', not {!r}".format (info))
        # no Note, plain old "out"
        else:
            returns.insert (0, function_push_ret_bindings.format ('ret'))
        call = function_with_ret_bindings.format (
                call = _call,
                type = func.ret_type)
    else:
        call = _call
    # now generate
    free_stuff = [function_free_bindings.format (*need_free) for need_free in frees]
    return function_wrapper_bindings.format (
            name = func,
            arguments = '\n    '.join (arg_decl + array_decl) or '// No arguments',
            call = call,
            push_rets = '\n    '.join (returns) or '// No returns',
            free_stuff = '\n    '.join (free_stuff) or '// Nothing to be freed',
            ret_num = len (returns))

# Module initialization templates and generator
module_bindings = r"""{inclua_notice}
{header}
{includes}

{push_check}
{enums}
{records}
////////////////////////////////////////////////////////////////////////////////
//  Callbacks
////////////////////////////////////////////////////////////////////////////////
lua_State *callback_State = nullptr;
{callbacks}

////////////////////////////////////////////////////////////////////////////////
//  Functions
////////////////////////////////////////////////////////////////////////////////
{functions}

////////////////////////////////////////////////////////////////////////////////
//  Module initialization
////////////////////////////////////////////////////////////////////////////////
extern "C" int luaopen_{module} (lua_State *L) {{
    const luaL_Reg functions[] = {{
        {func_register}
        {{ NULL, NULL }},
    }};
    luaL_newlib (L, functions);
    {record_register}
    {enum_register}
    {constant_register}
    // lua_State for function arguments
    callback_State = L;

    return 1;
}}
"""
module_include_bindings = '#include "{file}"'
module_func_reg_bindings = '{{ "{alias}", wrap_{func} }},'
module_record_register_bindings = """
    // {record}
    inclua_register_{trimmed} (L);
    lua_setfield (L, -2, "{alias}");"""
module_enum_register_bindings = """
    // enum {enum}
    inclua_register_{enum} (L);"""
module_enum_register_scoped_bindings = """
    // enum {enum}
    lua_newtable (L);
    inclua_register_{enum} (L);
    lua_setfield (L, -2, "{alias}");"""
module_constant_register_bindings = """
    // constant {name}
    inclua_push (L, {value});
    lua_setfield (L, -2, "{name}");"""

def generate_lua (G):
    """Function that generates bindings for Lua 5.2+"""
    V = Visitor ()
    for h in G.headers:
        V.parse_header (h, G.clang_args)

    bind = V.apply_ignores (G)

    includes = [module_include_bindings.format (file = file) for file in G.headers]
    # push/check definitions
    push_check = [_generate_record_push_check (record) for record in bind['records']]
    # definitions
    records = [_generate_record (record, G.get_note (record)) for record in bind['records']]
    enums = [_generate_enum (G, enum) for enum in bind['enums']]
    functions = [_generate_function (func, G.get_note (func)) for func in bind['functions']]
    # registration
    func_register = [module_func_reg_bindings.format (alias = G.final_name (func), func = func) for func in bind['functions']]

    record_register = [module_record_register_bindings.format (
            record = record,
            trimmed = _trim_prefix (str (record)),
            alias = _trim_prefix (G.final_name (record)))
            for record in bind['records']]
    enum_register = [(G.is_scoped (enum) and module_enum_register_scoped_bindings or module_enum_register_bindings).format (
            enum = _trim_prefix (str (enum)),
            alias = _trim_prefix (G.final_name (enum)))
            for enum in bind['enums']]
    constant_register = [module_constant_register_bindings.format (name = name, value = value)
            for name, value in bind['constants']]

    return module_bindings.format (
            module = G.mod_name,
            inclua_notice = GeneralInfo.C_notice,
            header = inclua_hpp,
            includes = '\n'.join (includes),
            push_check = '\n'.join (push_check),
            records = '\n'.join (records),
            enums = '\n'.join (enums),
            callbacks = '\n'.join (callbacks),
            functions = '\n'.join (functions),
            func_register = '\n        '.join (func_register) or '// No functions',
            record_register = '\n'.join (record_register),
            enum_register = '\n'.join (enum_register),
            constant_register = '\n'.join (constant_register))

Generator.add_generator ('lua', generate_lua, '\n'.join ([
"Inclua Lua wrapper generator",
"============================",
"What you should know:",
"",
"- generated code is C++11",
"- nothing is defined in global scope, everything is in the module table",
"- doesn't yet support input default arguments",
"- non opaque structs/unions can be instantiated with the `new` function from",
"  it's metatable: `obj = my_module.struct_metatable.new ()`",
"- all structs/unions may index it's metatable if the key isn't present as a",
"  field. This way it is easy to include methods (and metamethods):",
"  `my_module.struct_metatable.__tostring = my_module.print_struct",
"  print (some_struct_in_memory)",
"  my_module.struct_metatable.someFunc = my_module.someFunc",
"  some_struct_in_memory:someFunc (extra_args)`",
"- every struct/union pointer is a Lua full userdata, which means that equality",
"  between pointers doesn't work like expected. This will be fixed soon",
"- all output parameters that are pointers are initialized with NULL, as some",
"  functions may relly on that to know if it worked",
"- structs/unions that have function pointers as fields cannot be bound",
]))

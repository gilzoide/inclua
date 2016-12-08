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
from . import Type
from .Generator import Generator
from .Visitor import Visitor
from .Error import IncluaError
from .Note import Note

# Struct/Union bindings templates and generator
record_bindings = r"""
////////////////////////////////////////////////////////////////////////////////
//  {struct_or_union} {alias}
////////////////////////////////////////////////////////////////////////////////
INCLUA_PUSH ({record});
INCLUA_CHECK ({record});
{non_opaque}

void inclua_register_{alias} (lua_State *L) {{
    luaL_newmetatable (L, "{record}");
    {metamethods}
    lua_pushliteral (L, "{record}");
    lua_setfield (L, -2, "__metatable");
}}
"""
record_non_opaque_bindings = r"""INCLUA_PUSH_NON_OPAQUE ({record});
INCLUA_CHECK_NON_OPAQUE ({record});

int inclua_push_new_{alias} (lua_State *L) {{
    lua_newuserdata (L, sizeof ({record}));
    luaL_setmetatable (L, "{record}");
    return 1;
}}

int inclua_index_{alias} (lua_State *L) {{
    {record} *obj = inclua_check<{record} *> (L, 1);
    const char *key = inclua_check<const char *> (L, 2);

    {index_lines}
    else {{
        luaL_getmetatable (L, "{record}");
        if (lua_getfield (L, -1, key) == LUA_TNIL) {{
            return luaL_error (L, "{struct_or_union} {alias} doesn't have a \"%s\" field", key);
        }}
        lua_rotate (L, -2, 1);
        lua_pop (L, 1);
    }}
    return 1;
}}

int inclua_new_index_{alias} (lua_State *L) {{
    {record} *obj = inclua_check<{record} *> (L, 1);
    const char *key = inclua_check<const char *> (L, 2);

    {new_index_lines}
    else return luaL_error (L, "{struct_or_union} {alias} doesn't have a \"%s\" field", key);

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
record_index_metatable_bindings = r"""
    lua_pushvalue (L, -1);
    lua_setfield (L, -2, "__index");
"""
record_index_bindings = '{0} (!strcmp (key, "{field}")) inclua_push (L, {ref_if_record}obj->{field});'
record_new_index_bindings = '{0} (!strcmp (key, "{field}")) obj->{field} = inclua_check<{type}> (L, 3);'

def _generate_record_index (record):
    return '\n    '.join ([record_index_bindings.format (i == 0 and 'if' or 'else if',
            field = f[0], type = f[1], ref_if_record = f[1].kind == 'record' and '&' or '')
            for i, f in enumerate (record.fields)])

def _generate_record_new_index (record):
    return '\n    '.join ([record_new_index_bindings.format (i == 0 and 'if' or 'else if', field = f[0], type = f[1])
            for i, f in enumerate (record.fields)])

def _generate_record (record, struct_or_union):
    """Generate record binding functions, taking care if record is opaque (got no fields)"""
    meta = record.alias or record.symbol.replace ('{} '.format (struct_or_union), '')
    if record.num_fields > 0:
        non_opaque = record_non_opaque_bindings.format (
                record = record,
                struct_or_union = struct_or_union,
                alias = meta,
                index_lines = _generate_record_index (record),
                new_index_lines = _generate_record_new_index (record))
        metamethods = record_metamethods_bindings.format (record = record, alias = meta)
    else:
        non_opaque, metamethods = '', record_index_metatable_bindings
    return record_bindings.format (
            record = record,
            struct_or_union = struct_or_union,
            alias = meta,
            non_opaque = non_opaque,
            metamethods = metamethods)

# Enum bindings templates and generator
enum_wrapper_bindings = r"""
////////////////////////////////////////////////////////////////////////////////
//  Enum {alias}
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
function_argument_in_bindings = '{type} arg{i} = inclua_check<{type}> (L, {i_stack});'
function_argument_out_bindings = '{type} arg{i};'
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
def _address_of (s):
    return '&{}'.format (s)
def _generate_function (func, notes):
    """Generate function bindings, taking care of the notes given, so that everything
    works really well, and makes people want to use your module"""
    notes = notes or ['in'] * func.num_args
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
            arg_decl.append (function_argument_in_bindings.format (type = ty, i = i + 1, i_stack = i_lua_stack))
            arg_call.append (function_argname_bindings.format (i = i + 1))
            i_lua_stack += 1
        elif info.kind == 'out':
            arg_decl.append (function_argument_out_bindings.format (type = ty.pointee_type, i = i + 1))
            argname = function_argname_bindings.format (i = i + 1)
            arg_call.append (_address_of (argname))
            returns.append (function_push_ret_bindings.format (argname))
            # always free the memory you alloc
            if info.free:
                frees.append ((info.free, argname))
        elif info.kind == 'array in':
            array_decl.append (function_argument_arrayin_bindings.format (
                    type = ty,
                    i = i + 1, i_stack = i_lua_stack,
                    size = ', '.join (map (lambda s: s in ['_', 'NULL'] and '(size_t *) NULL' or _address_of (s), info.dims))))
            argname = function_argname_bindings.format (i = i + 1)
            arg_call.append (argname)
            frees.append (('inclua_delete_array', '{}, {}'.format (argname, ', '.join (map (lambda s: s == '_' and 'NULL' or s, info.dims)))))
            i_lua_stack += 1
        elif info.kind == 'array out':
            argname = function_argname_bindings.format (i = i + 1)
            sizes = ', '.join (info.dims)
            array_decl.append (function_argument_arrayout_bindings.format (
                    type = ty,
                    i = i + 1,
                    sizes = sizes))
            returns.append (function_push_ret_array_bindings.format (argname, info.dims[0]))
            arg_call.append (argname)
            frees.append (('inclua_delete_array', '{}, {}'.format (argname, sizes)))
        elif info.kind == 'size in':
            arg_decl.append (function_argument_size_bindings.format (type = ty, i = i + 1))
            arg_call.append (function_argname_bindings.format (i = i + 1))
        elif info.kind == 'size out':
            arg_decl.append (function_argument_out_bindings.format (type = ty.pointee_type, i = i + 1))
            argname = function_argname_bindings.format (i = i + 1)
            arg_call.append (_address_of (argname))

    _call = function_call_bindings.format (sym = func, args = ', '.join (arg_call))
    # return
    if str (func.ret_type) != 'void':
        if len (notes) > func.num_args:
            info = Note.parse (notes[func.num_args])
            if info.kind == 'array out':
                sizes = ', '.join (info.dims)
                frees.append (('inclua_delete_array', 'ret, {}'.format (sizes)))
                returns.insert (0, function_push_ret_array_bindings.format ('ret', info.dims[0]))
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
module_bindings = """/* Inclua automatic generated wrapper
 * Licensa?
 */

#include "inclua_Lua.hpp"
{includes}

{structs}
{unions}
{enums}
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
    {struct_register}
    {union_register}
    {enum_register}

    return 1;
}}
"""
module_include_bindings = '#include "{file}"'
module_func_reg_bindings = '{{ "{alias}", wrap_{func} }},'
module_record_register_bindings = """
    // {struct_or_union} {record}
    inclua_register_{record} (L);
    lua_setfield (L, -2, "{alias}");"""
module_enum_register_bindings = """
    // Enum {enum}
    inclua_register_{enum} (L);"""
module_enum_register_scoped_bindings = """
    // Enum {enum}
    lua_newtable (L);
    inclua_register_{enum} (L);
    lua_setfield (L, -2, "{alias}");"""

def generate_lua (G):
    """Function that generates bindings for Lua 5.2+"""
    V = Visitor ()
    for h in G.headers:
        V.parse_header (h, G.clang_args)

    bind = V.apply_ignores (G)

    #include ""
    includes = [module_include_bindings.format (file = file) for file in G.headers]
    # definitions
    structs = [_generate_record (struct, 'struct') for struct in bind['structs']]
    unions = [_generate_record (union, 'union') for union in bind['unions']]
    enums = [_generate_enum (G, enum) for enum in bind['enums']]
    functions = [_generate_function (func, G.get_note (func)) for func in bind['functions']]
    # registration
    func_register = [module_func_reg_bindings.format (alias = G.final_name (func), func = func) for func in bind['functions']]

    trim_struct = lambda s: s.replace ('struct ', '')
    struct_register = [module_record_register_bindings.format (
            record = trim_struct (str (struct)),
            alias = trim_struct (G.final_name (struct)),
            struct_or_union = 'struct')
            for struct in bind['structs']]
    trim_union = lambda s: s.replace ('union ', '')
    union_register = [module_record_register_bindings.format (
            record = trim_union (str (union)),
            alias = trim_union (G.final_name (union)),
            struct_or_union = 'union')
            for union in bind['unions']]
    trim_enum = lambda s: s.replace ('enum ', '')
    enum_register = [(G.is_scoped (enum) and module_enum_register_scoped_bindings or module_enum_register_bindings).format (
            enum = trim_enum (str (enum)),
            alias = trim_enum (G.final_name (enum)))
            for enum in bind['enums']]

    return module_bindings.format (
            module = G.mod_name,
            includes = '\n'.join (includes),
            structs = '\n'.join (structs),
            unions = '\n'.join (unions),
            enums = '\n'.join (enums),
            functions = '\n'.join (functions),
            func_register = '\n        '.join (func_register) or '// No functions',
            struct_register = '\n'.join (struct_register),
            union_register = '\n'.join (union_register),
            enum_register = '\n'.join (enum_register))

Generator.add_generator ('lua', generate_lua)

import re
from . import Type
from .Generator import Generator
from .Visitor import Visitor
from .Error import IncluaError

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
record_non_opaque_bindings = r"""
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
            field = f[0], type = f[1], ref_if_record = isinstance (f[1], Type.RecordType) and '&' or '')
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
INCLUA_PUSH_ENUM ({enum});
INCLUA_CHECK_ENUM ({enum});

void inclua_register_{alias} (lua_State *L) {{
    {enum_constant_lines}
}}
"""
enum_constant_bindings = r"""inclua_push (L, {const}); lua_setfield (L, -2, "{const}");"""
def _generate_enum (enum):
    """Generate enum binding functions, pushing all of it's values to toplevel module,
    or a namespaced table"""
    lines = [enum_constant_bindings.format (const = const)
            for const in enum.values.keys ()]
    return enum_wrapper_bindings.format (
            enum = enum,
            alias = enum.alias or enum.symbol.replace ('enum ', ''),
            enum_constant_lines = '\n    '.join (lines))

# Function bindings templates and generator
function_wrapper_bindings = r"""
int wrap_{name} (lua_State *L) {{
    {arguments}
    {call}
    {push_rets}
    {free_arrays}
    return {ret_num};
}}"""
function_argument_in_bindings = '{type} arg{i} = inclua_check<{type}> (L, {i_stack});'
function_argument_out_bindings = '{type.pointee_type} arg{i};'
function_argument_size_bindings = '{type} arg{i};'
function_argument_arrayin_bindings = '{type} arg{i} = inclua_check_array<{type.pointee_type}> (L, {i_stack}, {size});'
function_argument_arrayin_until_bindings = '{type} arg{i} = inclua_check_array_plus<{type.pointee_type}> (L, {i_stack}, {trailing});'
function_argument_arrayout_bindings = '{type} arg{i} = new {type.pointee_type} [{size}];'
function_argname_bindings = '{}arg{i}'
function_with_ret_bindings = '{type} ret = {call}'
function_push_ret_bindings = 'inclua_push (L, {});'
function_push_ret_array_bindings = 'inclua_push_array (L, {}, {});'
function_call_bindings = '{sym} ({args});'
function_free_array_bindings = 'delete[] {};'
def _generate_function (func, notes):
    """Generate function bindings, taking care of the notes given, so that everything
    works really well, and makes people want to use your module"""
    notes = notes or [None] * func.num_args
    arg_decl = []
    array_decl = []
    arrays = []
    arg_call = []
    returns = []
    # process arguments, and their notes
    i_lua_stack = 1
    for i, ty, note in zip (range (func.num_args), func.arg_types, notes):
        note = note or 'in'
        if note == 'in':
            arg_decl.append (function_argument_in_bindings.format (type = ty, i = i + 1, i_stack = i_lua_stack))
            arg_call.append (function_argname_bindings.format ('', i = i + 1))
            i_lua_stack += 1
        elif note == 'out':
            arg_decl.append (function_argument_out_bindings.format (type = ty, i = i + 1))
            arg_call.append (function_argname_bindings.format ('&', i = i + 1))
            returns.append (function_push_ret_bindings.format (function_argname_bindings.format ('', i = i + 1)))
        elif note.startswith ('arrayin'):
            try:
                size = re.match (r'arrayin\[(.+)\]', note).group (1)
                array_decl.append (function_argument_arrayin_bindings.format (
                        type = ty,
                        i = i + 1, i_stack = i_lua_stack,
                        size = size))
            except:
                try:
                    trailing = re.match (r'arrayin\|(.+)', note).group (1)
                    array_decl.append (function_argument_arrayin_until_bindings.format (
                            type = ty,
                            i = i + 1, i_stack = i_lua_stack,
                            trailing = trailing))
                except:
                    raise IncluaError ('invalid "{}" note: need a size argument ("arrayin[size]") or a trailing element ("array|trailing")'.format (note))
            argname = function_argname_bindings.format ('', i = i + 1)
            arg_call.append (argname)
            arrays.append (argname)
            i_lua_stack += 1
        elif note.startswith ('arrayout'):
            argname = function_argname_bindings.format ('', i = i + 1)
            try:
                size = re.match (r'arrayout\[(.+)\]', note).group (1)
                array_decl.append (function_argument_arrayout_bindings.format (
                        type = ty,
                        i = i + 1,
                        size = size))
                returns.append (function_push_ret_array_bindings.format (argname, size))
            except:
                raise IncluaError ('invalid "{}" note: need a size argument ("arrayout[size]")'.format (note))
            arg_call.append (argname)
            arrays.append (argname)
        elif note == 'size':
            arg_decl.append (function_argument_size_bindings.format (type = ty, i = i + 1))
            arg_call.append (function_argname_bindings.format ('', i = i + 1))
        else:
            raise IncluaError ("Invalid note for function argument: {}".format (note))

    _call = function_call_bindings.format (sym = func, args = ', '.join (arg_call))
    # return
    if str (func.ret_type) != 'void':
        if len (notes) > func.num_args:
            note = notes[func.num_args]
            try:
                size = re.match (r'arrayout\[(.+)\]', note).group (1)
                arrays.append ('ret');
                returns.insert (0, function_push_ret_array_bindings.format ('ret', size))
            except:
                raise IncluaError ("Invalid note for function return: {}".format (note))
        else:
            returns.insert (0, function_push_ret_bindings.format ('ret'))
        call = function_with_ret_bindings.format (
                call = _call,
                type = func.ret_type)
    else:
        call = _call
    # now generate
    free_arrays = [function_free_array_bindings.format (arr) for arr in arrays]
    return function_wrapper_bindings.format (
            name = func,
            arguments = '\n    '.join (arg_decl + array_decl) or '// No arguments',
            call = call,
            push_rets = '\n    '.join (returns) or '// No returns',
            free_arrays = '\n    '.join (free_arrays) or '// No arrays to be freed',
            ret_num = len (returns))
    
# Module initialization templates and generator
module_bindings = """/* Inclua wrapper automático e pá
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
module_func_reg_bindings = '{{ "{func}", wrap_{func} }},'
module_record_register_bindings = """
    // {struct_or_union} {alias}
    inclua_register_{alias} (L);
    lua_setfield (L, -2, "{alias}");"""
module_enum_register_bindings = """
    // Enum {alias}
    inclua_register_{alias} (L);"""
module_enum_register_scoped_bindings = """
    // Enum {alias}
    lua_newtable (L);
    inclua_register_{alias} (L);
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
    enums = [_generate_enum (enum) for enum in bind['enums']]
    functions = [_generate_function (func, G.get_note (func)) for func in bind['functions']]
    # registration
    func_register = [module_func_reg_bindings.format (func = func) for func in bind['functions']]
    struct_register = [module_record_register_bindings.format (
            alias = struct.alias or struct.symbol.replace ('struct ', ''),
            struct_or_union = 'struct')
            for struct in bind['structs']]
    union_register = [module_record_register_bindings.format (
            alias = union.alias or union.symbol.replace ('union ', ''),
            struct_or_union = 'union')
            for union in bind['unions']]
    enum_register = [(G.is_scoped (enum) and module_enum_register_scoped_bindings or module_enum_register_bindings)
            .format (alias = enum.alias or enum.symbol.replace ('enum ', ''))
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

Generator.add_generator (generate_lua, 'lua')

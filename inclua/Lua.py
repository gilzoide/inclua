from . import Type
from .Generator import Generator
from .Visitor import Visitor

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
    """Generate record binding functions"""
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
    {call};
    return {ret_num};
}}"""
function_argument_bindings = '{type} arg{i} = inclua_check<{type}> (L, {i});'
function_with_ret_bindings = """{type} ret = {call};\n    inclua_push (L, ret)"""
def _call (func):
    args = ['arg{}'.format (i + 1) for i in range (func.num_args)]
    return """{0} ({1})""".format (func, ', '.join (args))

def _generate_function (func):
    arguments = [function_argument_bindings.format (type = ty, i = i + 1)
            for i, ty in enumerate (func.arg_types)] or ['// No args']
    if str (func.ret_type) != 'void':
        ret_num = 1
        call = function_with_ret_bindings.format (
                call = _call (func),
                type = func.ret_type)
    else:
        ret_num = 0
        call = _call (func)
    return function_wrapper_bindings.format (
            name = func,
            arguments = '\n    '.join (arguments),
            call = call,
            ret_num = ret_num)
    
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
    functions = [_generate_function (func) for func in bind['functions']]
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

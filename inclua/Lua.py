from . import Type, Visitor

# Struct bindings templates and generator
struct_bindings = r"""
////////////////////////////////////////////////////////////////////////////////
//  Struct {alias}
////////////////////////////////////////////////////////////////////////////////
INCLUA_PUSH ({struct});
INCLUA_CHECK ({struct});
{non_opaque}

void inclua_register_{alias} (lua_State *L) {{
    luaL_newmetatable (L, "{alias}");
    {metamethods}
    lua_pushliteral (L, "{alias}");
    lua_setfield (L, -2, "__metatable");
    luaL_setmetatable (L, "{alias}");
}}
"""
struct_non_opaque_bindings = r"""
int inclua_push_new_{alias} (lua_State *L) {{
    lua_newuserdata (L, sizeof ({struct}));
    luaL_setmetatable (L, "{alias}");
    return 1;
}}

int inclua_index_{alias} (lua_State *L) {{
    {struct} *obj = inclua_check<{struct} *> (L, 1);
    const char *key = inclua_check<const char *> (L, 2);

    {index_lines}
    else return luaL_error (L, "struct {alias} doesn't have a \"%s\" field", key);

    return 1;
}}

int inclua_new_index_{alias} (lua_State *L) {{
    {struct} *obj = inclua_check<{struct} *> (L, 1);
    const char *key = inclua_check<const char *> (L, 2);

    {new_index_lines}
    else return luaL_error (L, "struct {alias} doesn't have a \"%s\" field", key);

    return 0;
}}
"""
struct_metamethods_bindings = r"""
    const luaL_Reg metamethods[] = {{
        {{ "__index", inclua_index_{alias} }},
        {{ "__new_index", inclua_new_index_{alias} }},
        {{ "__call", inclua_push_new_{alias} }},
        {{ NULL, NULL }},
    }};
    luaL_setfuncs (L, metamethods, 0);
"""
struct_index_bindings = '{0} (!strcmp (key, "{field}")) inclua_push (L, obj->{field});'
struct_new_index_bindings = '{0} (!strcmp (key, "{field}")) obj->{field} = inclua_check<{type}> (L, 3);'

def _generate_struct_index (struct):
    return '\n    '.join ([struct_index_bindings.format (i == 0 and 'if' or 'else if', field = f[0], type = f[1])
            for i, f in enumerate (struct.fields)])

def _generate_struct_new_index (struct):
    return '\n    '.join ([struct_new_index_bindings.format (i == 0 and 'if' or 'else if', field = f[0], type = f[1])
            for i, f in enumerate (struct.fields)])

def _generate_struct (struct):
    """Generate Struct binding functions"""
    meta = struct.alias or struct.symbol.replace ('struct ', '')
    if struct.num_fields > 0:
        non_opaque = struct_non_opaque_bindings.format (
                struct = struct,
                alias = meta,
                index_lines = _generate_struct_index (struct),
                new_index_lines = _generate_struct_new_index (struct))
        metamethods = struct_metamethods_bindings.format (struct = struct, alias = meta)
    else:
        non_opaque, metamethods = '', '// No metamethods'
    return struct_bindings.format (
            struct = struct,
            alias = meta,
            non_opaque = non_opaque,
            metamethods = metamethods)

# Enum bindings templates and generator
enum_wrapper_bindings = r"""
////////////////////////////////////////////////////////////////////////////////
//  Enum {alias}
////////////////////////////////////////////////////////////////////////////////
void inclua_register_{alias} (lua_State *L) {{
    {enum_constant_lines}
}}
"""
enum_constant_bindings = r"""inclua_push<int> (L, {const}); lua_setfield (L, -2, "{const}");"""
def _generate_enum (enum):
    lines = [enum_constant_bindings.format (const = const)
            for const in enum.values.keys ()]
    return enum_wrapper_bindings.format (
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
        {func_reg}
        {{ NULL, NULL }},
    }};
    luaL_newlib (L, functions);
    {struct_register}
    {enum_register}

    return 1;
}}
"""
module_include_bindings = '#include "{file}"'
module_func_reg_bindings = '{{ "{func}", wrap_{func} }},'
module_struct_register_bindings = """
    // Struct {alias}
    inclua_register_{alias} (L);
    lua_setfield (L, -2, "{alias}");"""
module_enum_register_bindings = """
    // Enum {alias}
    inclua_register_{alias} (L);"""
class Generator:
    """Class that generates bindings for Lua 5.2+"""
    def __init__ (self, mod_name):
        self.structs = []
        self.mod_name = mod_name

    def module (self, mod_name):
        self.mod_name = mod_name

    def generate (self):
        V = Visitor.Visitor ()
        for h in self.headers:
            V.parse_header (h)
        includes = [module_include_bindings.format (file = file) for file in self.headers]
        structs = [_generate_struct (struct) for struct in V.structs]
        enums = [_generate_enum (enum) for enum in V.enums.values ()]
        functions = [_generate_function (func) for func in V.functions]
        func_reg = [module_func_reg_bindings.format (func = func) for func in V.functions]
        struct_register = [module_struct_register_bindings.format (
                alias = struct.alias or struct.symbol.replace ('struct ', ''))
                for struct in V.structs]
        enum_register = [module_enum_register_bindings.format (alias = enum.alias or enum.symbol.replace ('enum ', ''))
                for enum in V.enums.values ()]

        return module_bindings.format (
                module = self.mod_name,
                includes = '\n'.join (includes),
                structs = '\n'.join (structs),
                enums = '\n'.join (enums),
                functions = '\n'.join (functions),
                func_reg = '\n        '.join (func_reg) or '// No functions',
                struct_register = '\n'.join (struct_register),
                enum_register = '\n'.join (enum_register))

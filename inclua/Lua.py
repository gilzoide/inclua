from . import Type, Visitor

def generate_struct (struct):
    """Generate Struct binding functions"""
    content = ["""
////////////////////////////////////////////////////////////////////////////////
//  {0}
////////////////////////////////////////////////////////////////////////////////
INCLUA_PUSH ({0});
INCLUA_CHECK ({0});"""]
    # struct is not opaque
    if len (struct.fields):
        # __call metamethod
        content.append ("""
int inclua_push_new_{1} (lua_State *L) {{
    lua_newuserdata (L, sizeof ({0}));
    luaL_setmetatable (L, "{0}");
    return 1;
}}""")

        # __index metamethod
        content.append ("""
int inclua_index_{1} (lua_State *L) {{
    {0} *obj = inclua_check<{0} *> (L, 1);
    const char *key = inclua_check<const char *> (L, 2);
""")
        for i, field in enumerate (struct.fields):
            content.append ("""    {0} (!strcmp (key, "{1}")) inclua_push (L, obj->{1});"""
                    .format (i == 0 and 'if' or 'else if', field[0]))
        content.append ("""    else return luaL_error (L, "struct {1} doesn't have a \\"%s\\" field", key);
    
    return 1;
}}""")
        # __newindex metamethod
        content.append ("""
int inclua_newindex_{1} (lua_State *L) {{
    {0} *obj = inclua_check<{0} *> (L, 1);
    const char *key = inclua_check<const char *> (L, 2);
""")
        for i, field in enumerate (struct.fields):
            content.append ("""    {0} (!strcmp (key, "{1[0]}")) obj->{1[0]} = inclua_check<{1[1]}> (L, 3);"""
                    .format (i == 0 and 'if' or 'else if', field))
        content.append ("""    else return luaL_error (L, "struct {1} doesn't have a \\"%s\\" field", key);
    
    return 0;
}}""")

    # struct register_struct
    content.append ("""
void inclua_register_{1} (lua_State *L) {{
    luaL_newmetatable (L, "{1}");""")
    if len (struct.fields):
        content.append (
"""    const luaL_Reg metamethods[] = {{
        {{ "__call", inclua_push_new_{1} }},
        {{ "__index", inclua_index_{1} }},
        {{ "__newindex", inclua_newindex_{1} }},
        {{ NULL, NULL }},
    }};
    luaL_setfuncs (L, metamethods, 0);
""")
    content.append (
"""    lua_pushliteral (L, "{1}");
    lua_setfield (L, -2, "__metatable");
    luaL_setmetatable (L, "{1}");
}}""")

    meta = str (struct).replace ('struct ', '')
    return '\n'.join (content).format (struct, meta)

def generate_function (func):
    def call (func):
        args = ['arg{}'.format (i + 1) for i in range (func.num_args)]
        return """{0.symbol} ({1}) """.format (func, ', '.join (args))

    content = ["""int wrap_{0.symbol} (lua_State *L) {{"""]
    for i, arg in enumerate (func.arg_types):
        content.append ("""    {ty} arg{i} = inclua_check<{ty}> (L, {i});""".format (i = i + 1, ty = arg))

    if str (func.ret_type) != 'void':
        content.append ("""    {0.ret_type} ret = {1};""")
        content.append ("""    inclua_push (L, ret);""")
        content.append ("""    return 1;""")
    else:
        content.append ("""    {1};""")
        content.append ("""    return 0;""")
    content.append ('}}\n')

    return '\n'.join (content).format (func, call (func))
    


class Generator:
    """Class that generates bindings for Lua 5.2+"""
    def __init__ (self):
        self.structs = []

    def module (self, mod_name):
        self.module = mod_name

    def generate (self):
        # Content list, for concatenating lines together with `join` later
        content = [
"""/* Inclua generated wrapper
 * LICENSA blablabla
 */

#include "inclua_Lua.hpp"
        """]
        V = Visitor.Visitor ()
        for h in self.headers:
            V.parse_header (h)
        content.extend (map (lambda h: '#include "{}"'.format (h), self.headers))

        # Structs: push, push_new, register_struct, check
        for S in V.structs:
            if isinstance (S, Type.StructType):
                content.append (generate_struct (S))

        # Module initialization
        content.append ("""
////////////////////////////////////////////////////////////////////////////////
//  Functions
////////////////////////////////////////////////////////////////////////////////""")
        for F in V.functions:
            content.append (generate_function (F))
        content.append (
"""////////////////////////////////////////////////////////////////////////////////
//  Module init
////////////////////////////////////////////////////////////////////////////////
extern "C" int luaopen_{0} (lua_State *L) {{
    const luaL_Reg functions[] {{""".format (self.module))
        for F in V.functions:
            content.append ("""        {{ "{0}", wrap_{0} }},""".format (F))
        content.append (
"""        { NULL, NULL },
    };
    luaL_newlib (L, functions);""")

        for S in V.structs:
            meta = str (S).replace ('struct ', '')
            content.append ("""
    // struct {1}
    inclua_register_{1} (L);
    lua_setfield (L, -2, "{1}");""".format (S, meta))

        content.append ("""
    return 1;
}
        """)
                

        return '\n'.join (content)

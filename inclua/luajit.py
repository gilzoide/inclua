"""
Binding generation for LuaJIT FFI.
"""

import re

import c_api_extract

from inclua.notice import lua_notice
from inclua.metatype import Metatype


def _c_code_from_def(d):
    """Generate standardized C definitions code"""
    kind = d['kind']
    if kind == 'var':
        return c_api_extract.typed_declaration(d['type'], d['name']) + ';'
    elif kind in ('struct', 'union'):
        typedef = d.get('typedef')
        fields = d.get('fields')
        return '{maybe_typedef}{kind} {name}{open_braces}{fields}{close_braces}{maybe_alias};'.format(
            maybe_typedef='typedef ' if typedef else '',
            kind=kind,
            name=d['name'],
            open_braces=' {\n' if fields else '',
            fields='\n'.join('  {};'.format(c_api_extract.typed_declaration(*f)) for f in fields),
            close_braces='\n}' if fields else '',
            maybe_alias=' ' + typedef if typedef else '',
        )
    elif kind == 'enum':
        typedef = d.get('typedef')
        return '{maybe_typedef}{kind} {name} {{\n{values}\n}}{maybe_alias};'.format(
            maybe_typedef='typedef ' if typedef else '',
            kind=kind,
            name=d['name'],
            values='\n'.join('  {0} = {1},'.format(*v) for v in d['values']),
            maybe_alias=' ' + typedef if typedef else '',
        )
    elif kind == 'function':
        return '{return_type} {name}({arguments});'.format(
            return_type=d['return_type'],
            name=d['name'],
            arguments=', '.join(c_api_extract.typed_declaration(*a) for a in d['arguments']),
        )
    elif kind == 'typedef':
        type = d['type']
        if type.startswith('struct') or type.startswith('union') or type.startswith('enum'):
            return ''
        else:
            return d['source'] + ';'
    else:
        return ''

template = lua_notice + r"""
local ffi = require 'ffi'

ffi.cdef[=[
{cdef}
]=]

local c_lib = ffi.load({lib_name!r}, {import_global})
{metatypes}
return {return_value}
"""

def _cdef(definitions):
    return '\n'.join(_c_code_from_def(d) for d in definitions)

def _stringify_metatype(metatype):
    definitions = ['  __name = {!r},'.format(metatype.name)]
    if metatype.destructor:
        definitions.append('  __gc = c_lib.{},'.format(metatype.destructor['name']))
    if metatype.methods:
        replace_method_name_re = re.compile(r'_?{}'.format(metatype.name))
        methods = '\n'.join('    {new_method_name} = c_lib.{method_name},'.format(
                method_name=method['name'],
                new_method_name=replace_method_name_re.sub('', method['name'], count=1).lstrip('_')
            )
            for method in metatype.methods)
        definitions.append('  __index = {{\n{}\n  }},'.format(methods))
    return 'lua_lib.{name} = ffi.metatype({record_name!r}, {{\n{definitions}\n}})'.format(
        name=metatype.name,
        record_name=metatype.spelling,
        definitions='\n'.join(definitions),
    )

def _metatypes(definitions):
    metatypes = Metatype.from_definitions(definitions)
    return "\nlocal lua_lib = setmetatable({{ c_lib = c_lib }}, {{ __index = c_lib }})\n{metatypes}\n".format(
        metatypes='\n'.join(_stringify_metatype(metatype) for metatype in metatypes),
    )

def generate(definitions, module_name, import_global=False, generate_metatypes=False):
    lib_name = module_name
    cdef = _cdef(definitions)
    metatypes = _metatypes(definitions) if generate_metatypes else ''
    return template.format(
        cdef=cdef,
        lib_name=lib_name,
        import_global='true' if import_global else 'false',
        metatypes=metatypes,
        return_value='lua_lib' if generate_metatypes else 'c_lib',
    )

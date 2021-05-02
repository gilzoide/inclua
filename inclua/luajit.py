"""
Binding generation for LuaJIT FFI.
"""

import re

import c_api_extract

from inclua.namespace import canonicalize
from inclua.notice import lua_notice
from inclua.metatype import Metatype


def _c_code_from_def(d):
    """Generate standardized C definitions code"""
    kind = d['kind']
    if kind == 'var':
        return c_api_extract.typed_declaration(d['type']['spelling'], d['name']) + ';'
    elif kind in ('struct', 'union'):
        typedef = d['name'] if not d['spelling'].startswith(kind) else ''
        fields = d.get('fields')
        return '{maybe_typedef}{kind} {name}{open_braces}{fields}{close_braces}{maybe_alias};'.format(
            maybe_typedef='typedef ' if typedef else '',
            kind=kind,
            name=d['name'],
            open_braces=' {\n' if fields else '',
            fields='\n'.join('  {};'.format(c_api_extract.typed_declaration(f[0]['spelling'], f[1])) for f in fields),
            close_braces='\n}' if fields else '',
            maybe_alias=' ' + typedef if typedef else '',
        )
    elif kind == 'enum':
        typedef = d['name'] if not d['spelling'].startswith(kind) else ''
        return '{maybe_typedef}{kind} {name} {{\n{values}\n}}{maybe_alias};'.format(
            maybe_typedef='typedef ' if typedef else '',
            kind=kind,
            name=d['name'],
            values='\n'.join('  {0} = {1},'.format(*v) for v in d['values']),
            maybe_alias=' ' + typedef if typedef else '',
        )
    elif kind == 'function':
        return '{return_type} {name}({arguments});'.format(
            return_type=d['return_type']['spelling'],
            name=d['name'],
            arguments=', '.join(c_api_extract.typed_declaration(a[0]['spelling'], a[1]) for a in d['arguments']),
        )
    elif kind == 'typedef':
        # pure enum/struct/union typedefs are already handled by their declarations
        # if re.match(r'(struct|union|enum)\s+\S+$', d['type']):
            # return ''
        return 'typedef {};'.format(c_api_extract.typed_declaration(d['type']['spelling'], d['name']))
    else:
        return ''

TEMPLATE = lua_notice + r"""
local ffi = require 'ffi'

ffi.cdef[=[
{cdef}
]=]

local c_lib = ffi.load({lib_name!r})
local lua_lib = setmetatable({{ c_lib = c_lib }}, {{ __index = c_lib }})
{metatypes}
{namespaced_defs}
return lua_lib
"""

def _cdef(definitions):
    return '\n'.join(_c_code_from_def(d) for d in definitions)

def _method_to_string(method, indent):
    name, literal = method
    literal = literal.replace('\n', '\n' + indent).strip()
    return '{indent}{name} = {literal},'.format(
        indent=indent,
        name=name,
        literal=literal,
    )

def _stringify_metatype(metatype, namespace_prefixes):
    definitions = ['  __name = {!r},'.format(metatype.name)]
    if metatype.destructor:
        definitions.append('  __gc = c_lib.{},'.format(metatype.destructor['name']))
    for method in metatype.native_methods:
        if method[0].startswith('__'):
            definitions.append(_method_to_string(method, '  '))
    if metatype.methods or metatype.native_methods:
        definitions.append('  __index = {')
        replace_method_name_re = re.compile(r'_?{0}'.format(metatype.unprefixed))
        for method in metatype.methods:
            canonicalized_name = canonicalize(method['name'], namespace_prefixes)
            definitions.append('    {new_method_name} = c_lib.{method_name},'.format(
                method_name=method['name'],
                new_method_name=replace_method_name_re.sub('', canonicalized_name, count=1).lstrip('_')
            ))
        for method in metatype.native_methods:
            if not method[0].startswith('__'):
                definitions.append(_method_to_string(method, '    '))
        definitions.append('  },')
    return 'lua_lib.{name} = ffi.metatype({record_name!r}, {{\n{definitions}\n}})'.format(
        name=metatype.unprefixed,
        record_name=metatype.spelling,
        definitions='\n'.join(definitions),
    )

def _metatypes(metatypes):
    return 

def _namespaced_defs(definitions, namespace_prefixes):
    if not namespace_prefixes:
        return ''

    prefixed = {}
    for d in definitions:
        name = d.get('typedef') or d['name']
        if d['kind'] in ('typedef', 'enum', 'struct', 'union') or name in prefixed:
            continue
        canonicalized = canonicalize(name, namespace_prefixes)
        if name != canonicalized:
            prefixed[name] = canonicalized
    return '\n'.join('lua_lib.{unprefixed} = lua_lib.{name}'.format(
        name=name,
        unprefixed=unprefixed
    ) for name, unprefixed in prefixed.items())

def generate(definitions, module_name, metatypes=[], namespace_prefixes=[]):
    lib_name = module_name
    cdef = _cdef(definitions)
    metatypes_text = '\n'.join(_stringify_metatype(metatype, namespace_prefixes) for metatype in metatypes)
    namespaced_defs = _namespaced_defs(definitions, namespace_prefixes)
    return TEMPLATE.format(
        cdef=cdef,
        lib_name=lib_name,
        metatypes=metatypes_text,
        namespaced_defs=namespaced_defs,
    )

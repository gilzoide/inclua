"""
Binding generation for LuaJIT FFI.
"""

import re

import c_api_extract

from inclua.notice import lua_notice


def _remove_prefix(s, prefix):
    return s[s.startswith(prefix) and len(prefix):]

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
            name=_remove_prefix(d['name'], kind),
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
            name=_remove_prefix(d['name'], kind),
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

return ffi.load({lib_name!r}, {import_global})
"""

def _module_name(module_name):
    return re.sub('[^_a-zA-Z]', '_', module_name)

def _raw_module_name(module_name):
    return 'c_' + module_name

def _cdef(definitions):
    return '\n'.join(_c_code_from_def(d) for d in definitions)

def _include_in_metatypes(definition):
    return definition['kind'] in ('struct', 'union')

def _metatypes(definitions, module_name):
    included_definitions = []
    for d in definitions:
        if _include_in_metatypes(d):
            typename = d.get('typedef') or d.get('name')
            symbol = _remove_prefix(typename, d['kind'] + ' ')
            code = r"{module_name}.{symbol} = ffi.metatype({typename!r}, {{}})".format(
                module_name=module_name,
                typename=typename,
                symbol=symbol,
            )
            included_definitions.append(code)
    return '\n'.join(included_definitions)

def generate(definitions, module_name, import_global):
    lib_name = module_name
    module_name = _module_name(module_name)
    cdef = _cdef(definitions)
    raw_module_name = _raw_module_name(module_name)
    metatypes = _metatypes(definitions, module_name)
    return template.format(
        cdef=cdef,
        lib_name=lib_name,
        import_global='true' if import_global else 'false',
    )

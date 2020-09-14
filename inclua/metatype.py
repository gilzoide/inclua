"""
Extract object orientation-like patterns from C definitions.
"""

import re

import c_api_extract

from inclua.namespace import canonicalize


class Metatype:
    def __init__(self, definition, namespace_prefixes=[]):
        self.definition = definition
        self.spelling = definition.get('typedef') or '{kind} {name}'.format(**definition)
        self.opaque = not definition.get('fields')
        self.name = definition.get('typedef') or t.get('name')
        self.unprefixed = canonicalize(self.name, namespace_prefixes)
        self.methods = []
        self.constructors = []
        self.destructor = None

    @classmethod
    def from_definitions(cls, definitions, namespace_prefixes):
        metatypes = [cls(t, namespace_prefixes) for t in definitions if t['kind'] in ('struct', 'union')]
        metatype_by_name = { t.name: t for t in metatypes }
        destructor_re = re.compile(r'release|destroy|unload|deinit|finalize', flags=re.I)
        for f in definitions:
            try:
                return_type = c_api_extract.base_type(f['return_type'])
                metatype = metatype_by_name[return_type]
                if metatype.unprefixed in f['name']:
                    metatype.constructors.append(f)
            except KeyError:
                pass

            try:
                first_argument_base = c_api_extract.base_type(f['arguments'][0][0])
                metatype = metatype_by_name[first_argument_base]
                if metatype.unprefixed not in f['name']:
                    continue
                if len(f['arguments']) == 1 and destructor_re.search(f['name']):
                    metatype.destructor = f
                else:
                    metatype.methods.append(f)
            except (KeyError, IndexError):
                pass
        return metatypes


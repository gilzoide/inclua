"""
Extract object orientation-like patterns from C definitions.
"""

import re

import c_api_extract


class Metatype:
    def __init__(self, definition):
        self.definition = definition
        self.spelling = definition.get('typedef') or '{kind} {name}'.format(**definition)
        self.opaque = not definition.get('fields')
        self.name = definition.get('typedef') or t.get('name')
        self.methods = []
        self.destructor = None

    @classmethod
    def from_definitions(cls, definitions):
        metatypes = [cls(t) for t in definitions if t['kind'] in ('struct', 'union')]
        by_name = { t.name: t for t in metatypes }
        destructor_re = re.compile(r'release|destroy|unload|deinit|finalize', flags=re.I)
        for f in definitions:
            try:
                first_argument_base = c_api_extract.base_type(f['arguments'][0][0])
                metatype = by_name[first_argument_base]
                if metatype.name not in f['name']:
                    continue
                if len(f['arguments']) == 1 and destructor_re.search(f['name']):
                    metatype.destructor = f
                else:
                    metatype.methods.append(f)
            except (KeyError, IndexError):
                pass
        return metatypes


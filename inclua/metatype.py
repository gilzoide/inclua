"""
Extract object orientation-like patterns from C definitions.
"""

import re

import c_api_extract

from inclua.namespace import canonicalize


class Metatype:
    def __init__(self, definition, namespace_prefixes=[]):
        self.definition = definition
        self.spelling = definition.get('spelling')
        self.name = definition.get('name')
        self.fields = definition.get('fields')
        self.opaque = not self.fields
        self.unprefixed = canonicalize(self.name, namespace_prefixes)
        self.aliases = {self.unprefixed}
        self.methods = []
        self.native_methods = []
        self.destructor = None

    def add_native_definition(self, key, value):
        self.native_methods.append((key, value))

    @classmethod
    def from_definitions(cls, definitions, namespace_prefixes, annotations):
        metatypes = [cls(t, namespace_prefixes)
                     for t in definitions
                     if t['kind'] in ('struct', 'union')
                     and not annotations.should_ignore(t['name'])]
        metatype_by_name = {t.name: t for t in metatypes}
        for t in definitions:
            if t['kind'] == 'typedef':
                try:
                    metatype = metatype_by_name[t['type']['base']]
                    metatype.aliases.add(t['name'])
                    metatype_by_name[t['name']] = metatype
                except KeyError:
                    pass
        if annotations:
            for name, d in annotations.items():
                try:
                    metatype = metatype_by_name[name]
                    for key, value in d.items():
                        metatype.add_native_definition(key, value)
                except KeyError:
                    pass
        destructor_re = re.compile(r'release|destroy|unload|deinit|finalize|dispose|close', flags=re.I)
        for f in definitions:
            try:
                if annotations.should_ignore(f['name']):
                    continue
                first_argument_base = f['arguments'][0][0]['base']
                metatype = metatype_by_name[first_argument_base]
                if metatype.unprefixed.lower() in f['name'].lower() and len(f['arguments']) == 1 and destructor_re.search(f['name']):
                    metatype.destructor = f
                else:
                    metatype.methods.append(f)
            except (KeyError, IndexError):
                pass
        return metatypes

"""
Extract object orientation-like patterns from C definitions.
"""

import re

import c_api_extract

from inclua.namespace import canonicalize


DESTRUCTOR_RE = re.compile(r'release|destroy|unload|deinit|finalize|dispose|close', flags=re.I)

class OOP:
    def __init__(self, definitions, namespace_prefixes, annotations):
        self.types = {}
        self.unprefixed = {}
        self.aliases = {}
        self.methods = {}
        self.native_methods = {}
        self.destructor = {}

        for d in definitions:
            if d.kind == 'typedef':
                known_type = self.types.get(d.type.base)
                if known_type:
                    self.types[d.name] = known_type
                    self.aliases[known_type.name].add(d.name)
            elif d.kind in ('struct', 'union'):
                type_name = d.name
                unprefixed = canonicalize(type_name, namespace_prefixes)
                self.types[type_name] = d
                self.unprefixed[type_name] = unprefixed
                self.aliases[type_name] = {unprefixed}
                self.methods[type_name] = []
                self.native_methods[type_name] = []
                self.destructor[type_name] = None
        if annotations:
            for name, d in annotations.items():
                try:
                    the_type = self.types[name]
                    for key, value in d.items():
                        self.native_methods[name].append((key, value))
                except KeyError:
                    pass
        for f in definitions:
            try:
                if annotations.should_ignore(f.name):
                    continue
                first_argument_base = f.arguments[0].type.base
                the_type = self.types[first_argument_base]
                if the_type.unprefixed.lower() in f.name.lower() and len(f.arguments) == 1 and DESTRUCTOR_RE.search(f.name):
                    self.destructor[the_type.name] = f
                else:
                    self.methods[the_type.name].append(f)
            except (KeyError, AttributeError, IndexError):
                pass

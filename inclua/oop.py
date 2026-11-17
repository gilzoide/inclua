"""
Extract object orientation-like patterns from C definitions.
"""

import re

import c_api_extract

from inclua.namespace import canonicalize


DESTRUCTOR_RE = re.compile(r'release|destroy|unload|deinit|finalize|dispose|close', flags=re.I)

class OOP:
    def __init__(self, definitions, namespace_prefixes, annotations, pod=False):
        self.types = {}
        self.unprefixed = {}
        self.methods = {}
        self.native_methods = {}
        self.destructor = {}

        for d in definitions:
            if d.kind == 'typedef' and d.root().is_record():
                self.types[d.name] = d.root()
            elif d.is_record():
                unprefixed = canonicalize(d.name, namespace_prefixes)
                self.types[d.spelling] = d
                self.types[d.name] = d
                self.types[unprefixed] = d
                self.unprefixed[d.spelling] = unprefixed
                self.methods[d.spelling] = []
                self.native_methods[d.spelling] = []
                self.destructor[d.spelling] = None
        if annotations:
            for name, d in annotations.items():
                try:
                    the_type = self.types[name]
                    for key, value in d.items():
                        self.native_methods[the_type.spelling].append((key, value))
                except KeyError:
                    pass
        if pod:
            return
        for f in definitions:
            try:
                if annotations.should_ignore(f.name):
                    continue
                first_argument = f.arguments[0].type
                if first_argument.is_pointer():
                    first_argument = first_argument.element_type.root()
                the_type = self.types[first_argument.spelling]
                if len(f.arguments) == 1 and DESTRUCTOR_RE.search(f.name):
                    self.destructor[the_type.spelling] = f
                else:
                    self.methods[the_type.spelling].append(f)
            except (KeyError, AttributeError, IndexError):
                pass

    def iter_types(self):
        for key in self.unprefixed.keys():
            yield self.types[key]

    def get_unprefixed_name(self, type):
        root = type.root()
        return self.unprefixed.get(root.spelling, root.name)

    def get_methods(self, type):
        return self.methods.get(type.root().spelling, [])

    def get_native_methods(self, type):
        return self.native_methods.get(type.root().spelling, [])

    def get_destructor(self, type):
        return self.destructor.get(type.root().spelling, None)

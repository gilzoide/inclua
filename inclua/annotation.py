"""
Extra annotations about the API.

Supports ignoring definitions, forcing records as opaque, annotating function
parameters as output, array or array size.
"""

import re
from typing import AnyStr, Dict, Optional

from inclua.error import IncluaError


IGNORE_TAG = 'ignore'
OPAQUE_TAG = 'opaque'
ARRAY_RE = re.compile(r'''
array \s* \[
    ([^]]+)
\] \s* (in|out|inout)?
''', re.X)


class Annotations(dict):
    def parse(self, raw_annotations: Dict):
        for k, v in raw_annotations.items():
            self[k] = self._parse(v)

    def get_name(self, name):
        try:
            return self[name]['rename']
        except KeyError:
            return name

    def is_array(self, funcname, argname) -> bool:
        try:
            return self[funcname][argname]['kind'] == 'array'
        except KeyError:
            return False

    def should_ignore(self, name):
        return self.get(name) == IGNORE_TAG

    @classmethod
    def _parse(cls, value):
        if isinstance(value, dict):
            annotations = {}
            for k, v in value.items():
                if not isinstance(v, str):
                    raise IncluaError("Annotation values must be text")
                m = ARRAY_RE.match(v)
                if m:
                    annotations[k] = {
                        'kind': 'array',
                        'size': m.group(1),
                        'inout': m.group(2) or 'in',
                    }
                else:
                    annotations[k] = v
            return annotations
        else:
            return value


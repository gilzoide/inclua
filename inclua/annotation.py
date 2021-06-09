"""
Extra annotations about the API.

Supports ignoring definitions, forcing records as opaque, annotating function
parameters as output, array or array size.

Examples:
```c
struct IntList {
    int *arr;
    size_t size;
};

struct _private {}
```
```yaml
IntList:
  arr:
    size: size  # `arr` is an array of size `size`

_private: ignore  # should not appear in generated bindings
```
"""

from collections import Sequence
import re
from typing import AnyStr, Dict, Optional, Union

from inclua.error import IncluaError


IGNORE_TAG = 'ignore'
OPAQUE_TAG = 'opaque'
SIZE_TAG = 'size'


class Annotations(dict):
    def get_array_size(self, func_or_record: str, arg_or_field: Union[str, int]) -> str:
        try:
            return self[func_or_record][arg_or_field][SIZE_TAG]
        except KeyError:
            return ""

    def is_array(self, func_or_record: str, arg_or_field: Union[str, int]) -> bool:
        return bool(self.get_array_size(func_or_record, arg_or_field))

    def should_ignore(self, name) -> bool:
        return self.get(name) == IGNORE_TAG


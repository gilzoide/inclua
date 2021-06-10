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
ARRAY_TAG = 'array'
SIZE_TAG = 'size'
SIZE_OF_TAG = 'sizeof'
OUT_TAG = 'out'


class Annotations(dict):
    def get_array_size(self, func_or_record: str, arg_or_field: Union[str, int]) -> str:
        try:
            return self[func_or_record][arg_or_field][SIZE_TAG]
        except:
            return ""

    def is_array(self, func_or_record: str, arg_or_field: Union[str, int]) -> bool:
        if self.get_array_size(func_or_record, arg_or_field):
            return True
        try:
            arg_annotation = self[func_or_record][arg_or_field]
            return arg_annotation == ARRAY_TAG or bool(arg_annotation[ARRAY_TAG])
        except:
            return False

    def is_argument_size(self, func: str, arg: Union[str, int]) -> bool:
        try:
            func_annotation = self[func]
            for other_arg, annotations in func_annotation.items():
                if annotations.get(SIZE_TAG) == arg:
                    return True
        except:
            pass
        return False

    def is_argument_out(self, func: str, arg: Union[str, int]) -> bool:
        try:
            arg_annotation = self[func][arg]
            return arg_annotation == OUT_TAG or bool(arg_annotation[OUT_TAG])
        except:
            return False

    def should_ignore(self, name) -> bool:
        return self.get(name) == IGNORE_TAG


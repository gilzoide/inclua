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
IN_TAG = 'in'
OUT_TAG = 'out'
FREE_TAG = 'free'
FUNCTION_DATA_TAG = 'userdata'


class Annotations(dict):
    def get_nested(self, *args):
        try:
            value = self
            for k in args:
                value = value[k]
            return value
        except KeyError:
            return None

    def get_array_size(self, func_or_record: str, arg_or_field: Union[str, int]) -> str:
        """
        Get array size annotation for a function's argument or record's field.
        """
        try:
            return self[func_or_record][arg_or_field][SIZE_TAG]
        except:
            return ""

    def is_array(self, func_or_record: str, arg_or_field: Union[str, int]) -> bool:
        """
        Get whether a function's argument or record's field is annotated as an array.
        """
        if self.get_array_size(func_or_record, arg_or_field):
            return True
        try:
            arg_annotation = self[func_or_record][arg_or_field]
            return arg_annotation == ARRAY_TAG or bool(arg_annotation[ARRAY_TAG])
        except:
            return False

    def is_argument_size(self, func: str, arg: Union[str, int]) -> bool:
        """
        Get whether a function's argument is the size of any other argument.
        """
        try:
            func_annotation = self[func]
            for other_arg, annotations in func_annotation.items():
                if annotations.get(SIZE_TAG) == arg:
                    return True
        except:
            pass
        return False

    def is_argument_in(self, func: str, arg: Union[str, int]) -> bool:
        """
        Get whether a function's argument is used as input.

        Combine this with `out` annotation to mark an argument that is both
        input and output of the function.
        """
        try:
            arg_annotation = self[func][arg]
            return arg_annotation == IN_TAG or bool(arg_annotation[IN_TAG])
        except:
            return False

    def is_argument_out(self, func: str, arg: Union[str, int]) -> bool:
        """
        Get whether a function's argument is used as output.

        Its type should be a pointer for this to make sense.
        """
        try:
            arg_annotation = self[func][arg]
            return arg_annotation == OUT_TAG or bool(arg_annotation[OUT_TAG])
        except:
            return False

    def get_argument_userdata(self, func_or_record: str, arg_or_field: Union[str, int]) -> str:
        """
        Get the userdata annotation for a function's argument of record's field that.

        Userdata annotations mark which pointers is passed as data when calling function pointers.
        """
        try:
            return self[func_or_record][arg_or_field][FUNCTION_DATA_TAG]
        except:
            return ''

    def is_argument_userdata(self, func: str, arg: Union[str, int]) -> bool:
        """
        Get whether a function's argument is the userdata of any other argument.

        Its type will most likely be `void *` or `const void *`.
        """
        try:
            func_annotation = self[func]
            for other_arg, annotations in func_annotation.items():
                if annotations.get(FUNCTION_DATA_TAG) == arg:
                    return True
        except:
            pass
        return False

    def get_free_func(self, func: str, arg: str) -> str:
        """
        Get the free function that should be used to free the data of some output argument.
        """
        try:
            return self[func][arg][FREE_TAG]
        except:
            return ''

    def should_ignore(self, name) -> bool:
        return self.get(name) == IGNORE_TAG


"""Supported default notes for everything: functions, enums, records (struct/union),
whatever fits. This module specifies the grammar, functions to parse, and
classes that hold the needed information.

Grammar:
    Note = 'ignore' | Function | Enum

    Function = Array |  Inout
    Array = 'array[' Size '] ' (In | Out)
    Size = /.+?/
    Inout = In | Out [ Free ] | In Out
    In = 'in'
    Out = 'out'
    Free = 'free[' Identifier ']'
    Identifier = /[A-Za-z_]\w*/

    Enum = 'scope'
"""

import re
import operator
from functools import reduce
from .Error import IncluaError

class Note:
    """Note base class, an already parsed note with the information needed.
    The only common data is the kind, which is a lowered string with the
    note start string (see Grammar), so you can query which kind it is without
    need for `isinstance`"""
    def __init__ (self, kind):
        self.kind = kind

    def __repr__ (self):
        return 'Note ({!r})'.format (self.kind)

    @staticmethod
    def parse (s):
        """Method that parses a note. This method is overriden in each subclass,
        so they may parse themselves. Returns the first instance matched.
        Raises if no match"""
        # strip blank stuff that may come
        s = s.strip ()
        note = reduce (lambda a, b: a or b, map (lambda x: x.parse (s),
                [Ignore, Input, Output, ArrayInput, ArrayOutput]))
        if note: return note
        else:
            raise IncluaError ("Invalid note: {!r}".format (s))


class Ignore (Note):
    def __init__ (self):
        self.kind = 'ignore'
    def parse (s):
        if s == 'ignore': return Ignore ()

class Input (Note):
    def __init__ (self):
        self.kind = 'in'
    def parse (s):
        if s == 'in': return Input ()

class Output (Note):
    free_patt = r'out free\[([A-Za-z_]\w*)\]'
    def __init__ (self, free = None):
        self.kind = 'out'
        self.free = free
    def parse (s):
        if s == 'out':
            return Output ()
        else:
            free = re.match (Output.free_patt, s)
            return free and Output (free)

class Array:
    """Base class for Arrays, both input, output and inout. May have more than
    one dimension, which is cool!"""
    size_patt = r'\[(.+?)\]'
    array_patt = r'array(\[.+\])'
    def __init__ (self, dims):
        self.dims = dims
        self.ndims = len (dims)
    def parse (s):
        m = re.match (Array.array_patt, s)
        if m:
            dims_string = m.group (1)
            return re.findall (Array.size_patt, dims_string)

class ArrayInput (Array, Note):
    def __init__ (self, dims):
        self.kind = 'array in'
        super (ArrayInput, self).__init__ (dims)
    def parse (s):
        if s.rfind (' in') != -1:
            dims = Array.parse (s)
            return dims and ArrayInput (dims)

class ArrayOutput (Array, Note):
    def __init__ (self, dims):
        self.kind = 'array out'
        super (ArrayOutput, self).__init__ (dims)
    def parse (s):
        if s.rfind (' out') != -1:
            dims = Array.parse (s)
            return dims and ArrayOutput (dims)

## Copyright 2016 Gil Barbosa Reis <gilzoide@gmail.com>
# This file is part of Inclua.
#
# Inclua is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Inclua is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Inclua.  If not, see <http://www.gnu.org/licenses/>.

"""Supported default notes for everything: functions, enums, records (struct/union),
whatever fits. This module specifies the grammar, functions to parse, and
classes that hold the needed information.

Grammar:
    Note = 'ignore' | 'native' | Record | Function | Enum

    Record = 'opaque'

    Function = Array | Inout
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
                [Ignore, Native, Opaque, Input, Output, InOut, ArrayInput,
                        ArrayOutput, SizeInput, SizeOutput]))
        if note: return note
        else:
            raise IncluaError ("Invalid note: {!r}".format (s))


class Ignore (Note):
    def __init__ (self):
        self.kind = 'ignore'
    @staticmethod
    def parse (s):
        if s == 'ignore': return Ignore ()

class Native (Note):
    def __init__ (self):
        self.kind = 'native'
    @staticmethod
    def parse (s):
        if s == 'native': return Native ()

class Opaque (Note):
    def __init__ (self):
        self.kind = 'opaque'
    @staticmethod
    def parse (s):
        if s == 'opaque': return Opaque ()

class Input (Note):
    default_patt = r'=\s*(.+)'
    with_default_patt = r'in\s*' + default_patt
    def __init__ (self, default = None):
        self.kind = 'in'
        self.default = default
    @staticmethod
    def parse (s):
        if s == 'in':
            return Input ()
        else:
            default = re.match (Input.with_default_patt, s)
            return default and Input (default.group (1))

class Output (Note):
    free_patt = r'out\s+free\[([A-Za-z_]\w*)\]'
    def __init__ (self, free = None):
        self.kind = 'out'
        self.free = free
    @staticmethod
    def parse (s):
        if s == 'out':
            return Output ()
        else:
            free = re.match (Output.free_patt, s)
            return free and Output (free.group (1))

class InOut (Input, Output):
    def __init__ (self, default = None, free = None):
        Input.__init__ (self, default)
        Output.__init__ (self, free)
        self.kind = 'inout'
    @staticmethod
    def parse (s):
        if s.startswith ('inout'):
            default = re.search (Input.default_patt + '$', s)
            free = re.match (Output.free_patt, s[2:])
            return InOut (default and default.group (1), free and free.group (1))

class Array:
    """Base class for Arrays, both input, output and inout. May have more than
    one dimension, which is cool!"""
    size_patt = r'\[(.+?)\]\s*'
    array_patt = r'array\s*(\[.+\])' # Note that we don't exclude ';', and user may
                                  # include code where it doesn't belong (if C/C++).
                                  # frontends should be careful with this!
    def __init__ (self, dims):
        self.dims = dims
        self.ndims = len (dims)
    @staticmethod
    def parse (s):
        m = re.match (Array.array_patt, s)
        if m:
            dims_string = m.group (1)
            return re.findall (Array.size_patt, dims_string)

class ArrayInput (Array, Note):
    def __init__ (self, dims):
        self.kind = 'array in'
        Array.__init__ (self, dims)
    @staticmethod
    def parse (s):
        if s.rfind (' in') != -1:
            dims = Array.parse (s)
            return dims and ArrayInput (dims)

class ArrayOutput (Array, Note):
    def __init__ (self, dims):
        self.kind = 'array out'
        Array.__init__ (self, dims)
    @staticmethod
    def parse (s):
        if s.rfind (' out') != -1:
            dims = Array.parse (s)
            return dims and ArrayOutput (dims)

class SizeInput (Note):
    def __init__ (self):
        self.kind = 'size in'
    @staticmethod
    def parse (s):
        if s in ['size', 'size in']:
            return SizeInput ()

class SizeOutput (Note):
    def __init__ (self):
        self.kind = 'size out'
    @staticmethod
    def parse (s):
        if s == 'size out':
            return SizeOutput ()

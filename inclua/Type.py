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

"""Type information needed for bindings to do their jobs, based on
Clang.cindex.Type"""

import re
from .Decl import Decl
from .Error import IncluaError

def from_type (ty):
    # _ty = ty.get_canonical ()
    memoized = Type.from_type (ty)
    if memoized: return memoized

    kind = ty.kind.name
    if kind in ['INT', 'UINT', 'SHORT', 'USHORT', 'LONG', 'ULONG', 'LONGLONG'
            , 'ULONGLONG', 'SCHAR', 'CHAR_S', 'CHAR_U', 'UCHAR', 'CHAR16'
            , 'CHAR32' , 'INT128', 'UINT128']:
        return Type.from_type (ty, 'int')
    elif kind in ['FLOAT', 'FLOAT128', 'DOUBLE', 'LONGDOUBLE']:
        return Type.from_type (ty, 'float')
    elif kind == 'BOOL':
        return Bool.from_type (ty)
    elif kind in ['INCOMPLETEARRAY', 'CONSTANTARRAY', 'VARIABLEARRAY']:
        return ArrayType.from_type (ty)
    elif kind == 'VOID':
        return VoidType ()
    elif kind == 'POINTER':
        return PointerType.from_type (ty)
    elif kind == 'TYPEDEF':
        return Typedef.from_type (ty)
    elif kind == 'RECORD':
        return RecordType.from_type (ty)
    elif kind == 'ENUM':
        return Enum.from_type (ty)
    elif kind in ['FUNCTIONPROTO', 'FUNCTIONNOPROTO']:
        return FunctionType.from_type (ty)
    elif kind == 'ELABORATED':
        # anonymous records
        return RecordType.from_type (ty)
    elif kind == 'UNEXPOSED':
        return FunctionType.from_type (ty)
    else:
        raise IncluaError ('Clang TypeKind {} not supported: {}'.format (kind, ty.spelling))

def from_cursor (cur):
    try:
        return from_type (cur.type)
    except IncluaError as ex:
        print (ex)
        raise IncluaError ('{0!s} @ {1!s}'.format (ex, cur.location))

class Type (Decl):

    # Known types, for memoizing
    known_types = {}

    # Regex for giving anonymous enums/structs/unions a nice name based on it's location
    anonymous_patt = re.compile (r".+\((anonymous ).*(at .+)\)")

    def __init__ (self, symbol, kind, alias = None):
        Decl.__init__ (self, Type.fix_anonymous (symbol))
        self.kind = kind
        self.alias = alias

    def __str__ (self):
        return self.alias or self.symbol

    def __repr__ (self):
        return 'Type ("{}")'.format (self.symbol)

    def is_anonymous (self):
        return self.symbol.startswith ('anonymous')

    @staticmethod
    def fix_anonymous (symbol):
        # anonymous struct/union/enum
        is_anonymous = Type.anonymous_patt.match (symbol)
        if is_anonymous:
            symbol = re.sub (r'\W', '_', is_anonymous.group (1) + is_anonymous.group (2))
        return symbol

    @staticmethod
    def from_type (ty, kind = None):
        spelling = Type.fix_anonymous (ty.spelling)
        return Type.known_types.get (spelling) or kind and Type (spelling, kind)

    @staticmethod
    def remember_type (ty):
        Type.known_types[ty.symbol] = ty
        return ty

class Bool (Type):
    def __init__ (self):
        Type.__init__ (self, 'bool', 'bool')

    @staticmethod
    def from_type (ty):
        return Bool ()

class Typedef (Type):
    def __init__ (self, symbol, underlying_type):
        Type.__init__ (self, symbol, underlying_type.kind)
        self.underlying_type = underlying_type

    def __getattr__ (self, attr):
        if attr in ['symbol', 'underlying_type']:
            return getattr (self, attr)
        else:
            return getattr (self.underlying_type, attr)

    def __repr__ (self):
        return 'Typedef ({0!r}, {1!r}'.format (self.symbol, self.underlying_type)

    @staticmethod
    def from_type (ty):
        # print ('Typedef', ty.spelling, ty.get_canonical ().spelling)
        return Typedef (ty.spelling, from_type (ty.get_canonical ()))

class PointerType (Type):
    def __init__ (self, symbol, pointee_type):
        Type.__init__ (self, symbol, 'pointer' if pointee_type.kind != 'function' else 'functionpointer')
        self.pointee_type = pointee_type

    def __repr__ (self):
        return 'PointerType ({0!r}, {1!r})'.format (self.symbol, self.pointee_type)

    def __getattr__ (self, attr):
        if attr in ['symbol', 'alias', 'pointee_type']:
            return getattr (self, attr)
        else:
            return getattr (self.pointee_type, attr)

    @staticmethod
    def from_type (ty):
        return PointerType (ty.spelling, from_type (ty.get_pointee ()))

class ArrayType (Type):
    def __init__ (self, symbol, pointee_type):
        Type.__init__ (self, symbol, 'array')
        self.pointee_type = pointee_type

    def __str__ (self):
        return '{0!s} *'.format (self.pointee_type)

    def __repr__ (self):
        return 'ArrayType ({0!r}, {1!r})'.format (self.symbol, self.pointee_type)

    @staticmethod
    def from_type (ty):
        return Type.remember_type (ArrayType (ty.spelling, from_type (ty.get_array_element_type ())))

class VoidType (Type):
    def __init__ (self):
        Type.__init__ (self, 'void', 'void')

class RecordType (Type):
    def __init__ (self, symbol, fields = []):
        Type.__init__ (self, symbol, 'record')
        self.fields = fields
        self.num_fields = len (fields)

    def __repr__ (self):
        return 'RecordType ("{0!s}", {0.fields!s})'.format (self)

    @staticmethod
    def from_type (ty):
        fields = []
        for cur in ty.get_fields ():
            field_type = from_type (cur.type)
            # anonymous record fields: rename it wisely, so notes can be taken
            if field_type.is_anonymous ():
                field_type.alias = ty.spelling + '_field_' + cur.spelling
            fields.append ( (cur.spelling, field_type) )
        return Type.remember_type (RecordType (ty.spelling, fields))

class Enum (Type):
    def __init__ (self, symbol, values):
        Type.__init__ (self, symbol, 'enum')
        self.values = values

    def add_value (self, cursor):
        self.values[cursor.spelling] = cursor.enum_value

    def __str__ (self):
        return self.alias or self.symbol

    def __repr__ (self):
        return 'Enum ({0!r}, {1!r}, {2!r})'.format (self.symbol, self.values, self.alias)

    @staticmethod
    def from_type (ty):
        return Type.remember_type (Enum (ty.spelling, {}))

class FunctionType (Type):
    """Function pointer type (without the pointer stuff)"""
    def __init__ (self, symbol, ret_type, arg_types):
        Type.__init__ (self, symbol, 'function')
        self.ret_type = ret_type
        self.arg_types = arg_types
        self.num_args = len (arg_types)

    @staticmethod
    def from_type (ty):
        ret_type = from_type (ty.get_result ())
        arg_types = [from_type (a) for a in ty.argument_types ()] if ty.kind == 'FUNCTIONPROTO' else []
        return Type.remember_type (FunctionType (ty.spelling, ret_type, arg_types))

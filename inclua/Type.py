"""Type information needed for bindings to do their jobs, based on
Clang.cindex.Type"""

from .Decl import Decl

def from_type (ty):
    memoized = Type.from_type (ty)
    if memoized: return memoized

    kind = ty.kind.name
    if kind in ['INT', 'UINT', 'SHORT', 'USHORT', 'LONG', 'ULONG', 'LONGLONG'
            , 'ULONGLONG', 'CHAR_S', 'CHAR_U', 'UCHAR', 'CHAR16', 'CHAR32'
            , 'INT128', 'UINT128']:
        return IntType.from_type (ty)
    elif kind in ['FLOAT', 'FLOAT128', 'DOUBLE', 'LONGDOUBLE']:
        return FloatType.from_type (ty)
    elif kind in ['CONSTANTARRAY', 'VARIABLEARRAY']:
        return ArrayType.from_type (ty)
    elif kind == 'VOID':
        return VoidType ()
    elif kind == 'POINTER':
        return PointerType.from_type (ty)
    elif kind == 'RECORD':
        return StructType.from_type (ty)
    else:
        print ('Não conheço esse tipo:', kind)

def from_cursor (cur):
    return from_type (cur.type)


known_types = {}

class Type (Decl):
    def __init__ (self, symbol):
        super (Type, self).__init__ (symbol)

    def __str__ (self):
        return self.symbol

    def __repr__ (self):
        return 'Type ("{}")'.format (self.symbol)

    @staticmethod
    def from_type (ty):
        return known_types.get (ty.get_canonical ().spelling)

    @staticmethod
    def remember_type (ty):
        known_types[ty.symbol] = ty
        return ty

class IntType (Type):
    @staticmethod
    def from_type (ty):
        return Type.remember_type (IntType (ty.spelling))


class FloatType (Type):
    @staticmethod
    def from_type (ty):
        return Type.remember_type (FloatType (ty.spelling))

class ArrayType (Type):
    pass

class VoidType (Type):
    def __init__ (self):
        super (VoidType, self).__init__ ('void')

class PointerType (Type):
    def __init__ (self, symbol, pointee_type):
        super (PointerType, self).__init__ (symbol)
        self.pointee_type = pointee_type

    def __repr__ (self):
        return 'PointerType ("{}", {})'.format (self.symbol, self.pointee_type)

    @staticmethod
    def from_type (ty):
        return Type.remember_type (PointerType (ty.spelling, from_type (ty.get_pointee ())))

class StructType (Type):
    def __init__ (self, symbol, fields = [], alias = None):
        super (StructType, self).__init__ (symbol)
        self.fields = fields
        self.alias = alias

    def __str__ (self):
        return self.alias or self.symbol

    def __repr__ (self):
        return 'StructType ("{}", {})'.format (str (self), str (self.fields))

    @staticmethod
    def from_type (ty):
        fields = []
        for cur in ty.get_fields ():
            fields.append ((cur.spelling, from_type (cur.type)))
        return Type.remember_type (StructType (ty.spelling, fields))

"""Function declarations, with it's name, and types (parameters and return)"""

from . import Type
from .Decl import Decl

class Function (Decl):
    def __init__ (self, symbol, ret_type, arg_types):
        super (Function, self).__init__ (symbol)
        self.ret_type = ret_type
        self.arg_types = arg_types
        self.num_args = len (arg_types)

    def __repr__ (self):
        return 'Function ("{}", {}, {})'.format (self.symbol, self.ret_type, self.arg_types)

def from_cursor (cur):
    name = cur.spelling
    ret_type = Type.from_type (cur.result_type)
    arg_types = [Type.from_type (a.type) for a in cur.get_arguments ()]
    return Function (name, ret_type, arg_types)

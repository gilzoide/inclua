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

"""Function declarations, with it's name, and types (parameters and return)"""

from . import Type
from .Decl import Decl

class Function (Decl):
    def __init__ (self, symbol, ret_type, arg_types):
        Decl.__init__ (self, symbol)
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

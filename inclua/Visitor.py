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

"""AST visitor, using Clang for parsing/understanding of C code and returning
Types in a more useful way to Inclua"""

import clang.cindex as clang
import os.path as path
from sys import stderr
from . import Type, Function
from .Error import IncluaError

class Visitor:
    def __init__ (self):
        self.structs = set ()
        self.unions = set ()
        self.enums = {}
        self.functions = set ()
        self.index = clang.Index.create ()

    @staticmethod
    def find_path (file_name, clang_args):
        """Find `file_name` relative path, searching in local directory, then
        on the directories supplied by "-I" flags for clang.

        Raises if couldn't find the file anywhere"""
        dirs = ['.'] + list (map (lambda p: p[2:], filter (lambda s: s.startswith ('-I'), clang_args)))
        for d in dirs:
            file_path = path.join (d, file_name)
            if path.exists (file_path):
                return file_path
        raise IncluaError ("Couldn't find {!r} anywhere in {}".format (file_name, dirs))


    def parse_header (self, header_name, clang_args = []):
        header_path = Visitor.find_path (header_name, clang_args)
        tu = self.index.parse (header_path, args = clang_args
                , options = clang.TranslationUnit.PARSE_SKIP_FUNCTION_BODIES)

        visit_queue = list (tu.cursor.get_children ())
        self._visit (visit_queue, header_path)

    def apply_ignores (self, G):
        no_ignore = lambda x: not G.should_ignore (str (x))
        return {
            'structs'   :   list (filter (no_ignore, self.structs)),
            'enums'     :   list (filter (no_ignore, self.enums.values ())),
            'unions'    :   list (filter (no_ignore, self.unions)),
            'functions' :   list (filter (no_ignore, self.functions)),
        }

    def _visit (self, visit_queue, header_name):
        headers = set ()
        while visit_queue:
            cursor = visit_queue[0]
            del visit_queue[0]
            # Typedef: just alias the type
            if cursor.kind == clang.CursorKind.TYPEDEF_DECL:
                ty = Type.from_cursor (cursor)
                try:
                    ty.underlying_type.alias = cursor.spelling
                except:
                    pass
            if str (cursor.location.file) == header_name:
                # Structs
                if cursor.kind == clang.CursorKind.STRUCT_DECL:
                    self.structs.add (Type.from_cursor (cursor))
                # Unions
                elif cursor.kind == clang.CursorKind.UNION_DECL:
                    self.unions.add (Type.from_cursor (cursor))
                # Functions
                elif cursor.kind == clang.CursorKind.FUNCTION_DECL:
                    self.functions.add (Function.from_cursor (cursor))
                # Enums
                elif cursor.kind == clang.CursorKind.ENUM_DECL:
                    self.enums[cursor.hash] = Type.from_cursor (cursor)
                elif cursor.kind == clang.CursorKind.ENUM_CONSTANT_DECL:
                    # from pprint import pprint
                    # pprint (self.enums[cursor.semantic_parent.hash])
                    # print (cursor.semantic_parent.hash)
                    self.enums[cursor.semantic_parent.hash].add_value (cursor)
            # nome = str (cursor.location.file)
            # if not nome in headers:
                # print (str (cursor.location.file))
                # headers.add (nome)


            visit_queue.extend (cursor.get_children ())

"""AST visitor, using Clang for parsing/understanding of C code and returning
Types in a more useful way to Inclua"""

import clang.cindex as clang
from . import Type, Function

class Visitor:
    def __init__ (self):
        self.structs = set ()
        self.enums = set ()
        self.functions = []

    def parse_header (self, header_name):
        index = clang.Index.create ()
        tu = index.parse (header_name)

        declarations = []
        for c in tu.cursor.get_children ():
            self.visit (c, header_name)

    def visit (self, cursor, header_name):
        if str (cursor.location.file) == header_name:
            # Structs
            if cursor.kind == clang.CursorKind.STRUCT_DECL:
                self.structs.add (Type.from_cursor (cursor))
            elif cursor.kind == clang.CursorKind.TYPEDEF_DECL:
                record = Type.from_cursor (cursor)
                record.alias = cursor.spelling
                self.structs.add (record)
            elif cursor.kind == clang.CursorKind.FUNCTION_DECL:
                self.functions.append (Function.from_cursor (cursor))
                return

            for c in cursor.get_children ():
                self.visit (c, header_name)

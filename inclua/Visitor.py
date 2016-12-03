"""AST visitor, using Clang for parsing/understanding of C code and returning
Types in a more useful way to Inclua"""

import clang.cindex as clang
from . import Type, Function

class Visitor:
    def __init__ (self):
        self.structs = set ()
        self.unions = set ()
        self.enums = {}
        self.functions = []
        self.index = clang.Index.create ()

    def parse_header (self, header_name, clang_args = []):
        tu = self.index.parse (header_name, args = clang_args
                , options = clang.TranslationUnit.PARSE_SKIP_FUNCTION_BODIES)

        visit_queue = list (tu.cursor.get_children ())
        self.visit (visit_queue, header_name)

    def apply_ignores (self, G):
        no_ignore = lambda x: not G.should_ignore (str (x))
        return {
            'structs'   :   list (filter (no_ignore, self.structs)),
            'enums'     :   list (filter (no_ignore, self.enums.values ())),
            'unions'    :   list (filter (no_ignore, self.unions)),
            'functions' :   list (filter (no_ignore, self.functions)),
        }

    def visit (self, visit_queue, header_name):
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
                    self.functions.append (Function.from_cursor (cursor))
                # Enums
                elif cursor.kind == clang.CursorKind.ENUM_DECL:
                    self.enums[cursor.hash] = Type.from_cursor (cursor)
                elif cursor.kind == clang.CursorKind.ENUM_CONSTANT_DECL:
                    # from pprint import pprint
                    # pprint (self.enums[cursor.semantic_parent.hash])
                    # print ()
                    self.enums[cursor.semantic_parent.hash].add_value (cursor)
            # nome = str (cursor.location.file)
            # if not nome in headers:
                # print (str (cursor.location.file))
                # headers.add (nome)


            visit_queue.extend (cursor.get_children ())

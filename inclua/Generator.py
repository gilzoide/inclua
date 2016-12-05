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

import sys
import re

class Generator:
    """Class for wrapper generators. You can add the wrapper generator for
    your language"""

    languages = {}

    def __init__ (self, mod_name):
        self.headers = []
        self.mod_name = mod_name
        self.clang_args = []
        # annotations
        self.ignore_notes = { '_regex': [] }
        self.rename_notes = { '_regex': [] }
        self.scope_enum = set ()
        self.arg_notes = {}

    def add_header (self, header):
        self.headers.append (header);

    def set_clang_args (self, args):
        self.clang_args = args

    def extend_clang_args (self, args):
        self.clang_args.extend (args)

    # Ignore
    def ignore (self, symbol):
        self.ignore_notes[symbol] = True

    def ignore_regex (self, regex):
        self.ignore_notes['_regex'].append (re.compile (regex))

    def should_ignore (self, symbol):
        if self.ignore_notes.get (symbol): return True
        try:
            if self.arg_notes[symbol].kind == 'ignore': return True
        except:
            pass
        return any (map (lambda patt: patt.fullmatch (symbol), self.ignore_notes['_regex']))

    # Rename
    def rename (self, target, new_symbol_or_func):
        self.rename_notes[target] = new_symbol_or_func

    def rename_regex (self, regex, subst):
        self.rename_notes['_regex'].append ((re.compile (regex), subst))

    def final_name (self, symbol):
        symbol = str (symbol)
        new_symbol_or_func = self.rename_notes.get (symbol)
        if new_symbol_or_func:
            try:
                return new_symbol_or_func (symbol)
            except:
                return new_symbol_or_func
        else:
            for patt, subs in self.rename_notes['_regex']:
                new_symbol, n = patt.subn (subs, symbol)
                if n > 0:
                    return new_symbol
        return symbol

    # Scope Enum
    def scope (self, enum_symbol):
        self.scope_enum.add (enum_symbol)

    def is_scoped (self, enum):
        return str (enum) in self.scope_enum

    # Argument notes
    def note (self, symbol, note):
        self.arg_notes[symbol] = note

    def get_note (self, func):
        return self.arg_notes.get (str (func))

    # Generate, that's why we're here =]
    def generate (self, lang, output = sys.stdout):
        wrapper = Generator.languages[lang] (self)
        if output:
            try:
                output.write (wrapper)
            except:
                with open (output, 'w') as f:
                    f.write (wrapper)
        return wrapper

    @staticmethod
    def add_generator (func, lang):
        Generator.languages[lang] = func

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

    # Ignore
    def ignore (self, symbol):
        self.ignore_notes[symbol] = True

    def ignore_regex (self, regex):
        self.ignore_notes['_regex'].append (re.compile (regex))

    def should_ignore (self, symbol):
        if self.ignore_notes.get (symbol): return True
        return any (map (lambda patt: patt.fullmatch (symbol), self.ignore_notes['_regex']))

    # Rename
    def rename (self, target, new_symbol):
        self.rename_notes[symbol] = lambda s: new_symbol

    def rename_regex (self, regex, subst):
        self.rename_notes['_regex'].append ((re.compile (regex), subst))

    def final_name (self, symbol):
        try:
            return self.rename_notes[symbol]
        except:
            for patt, subs in self.rename_notes['_regex']:
                new_symbol, n = patt.sub (subs, symbol)
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

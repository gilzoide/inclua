import sys

class Generator:
    """Class for wrapper generators. You can add the wrapper generator for
    your language"""

    languages = {}

    def __init__ (self, mod_name):
        self.headers = []
        self.mod_name = mod_name
        self.clang_args = []

    def add_header (self, header):
        self.headers.append (header);

    def set_clang_args (self, args):
        self.clang_args = args

    def generate (self, lang, output = sys.stdout):
        wrapper = Generator.languages[lang] (self)
        if isinstance (output, basestring):
            with open (output, 'w') as f:
                f.write (wrapper)
        elif output:
            output.write (wrapper)
        return wrapper

    @staticmethod
    def add_generator (func, lang):
        Generator.languages[lang] = func

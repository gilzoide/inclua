"""Declarations that may have bindings, base class for the ones to be used"""

class Decl:
    def __init__ (self, symbol):
        self.symbol = symbol

    def __str__ (self):
        return self.symbol

    def __repr__ (self):
        return 'Decl ("{}")'.format (self.symbol)

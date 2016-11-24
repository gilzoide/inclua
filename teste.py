from inclua.Lua import *

mod = Generator ()
mod.module ('teste')

mod.headers = ['teste.h']

# mod.generate ()
print (mod.generate ())
# ignore_regex ('_.*')
# trim_prefix ('teste_')

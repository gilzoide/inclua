from inclua import *
import inclua.Lua

mod = Generator ('teste')
mod.add_header ('teste.h')
mod.generate ('lua')
# ignore_regex ('_.*')
# trim_prefix ('teste_')

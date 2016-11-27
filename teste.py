from inclua import *
import inclua.Lua

mod = Generator ('teste')
mod.add_header ('teste.h')

# teste dos ignores
mod.scope ('Nice')
mod.ignore_regex ('get')

mod.generate ('lua')

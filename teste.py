from inclua import *
import inclua.Lua

mod = Generator ('teste')
mod.add_header ('teste.h')

# teste das anotações
mod.scope ('Nice')
mod.ignore_regex ('get')
mod.note ('getAB', ['in', 'out', 'out'])
mod.note ('somaVet', ['arrayin[arg2]', 'size'])

mod.generate ('lua')

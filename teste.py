from inclua import *
import inclua.Lua

mod = Generator ('teste')
mod.add_header ('teste.h')

# teste das anotações
mod.scope ('Nice')
mod.ignore ('getOi')
mod.note ('getAB', ['in', 'out', 'out'])
mod.note ('somaVet', ['arrayin[arg2]', 'size'])
mod.note ('somaVetAte0', ['arrayin|0'])
mod.note ('range', ['arrayout[arg3 - arg2]', 'in', 'in'])
mod.note ('rangeAlloc', [
    'in',
    'in',
    'arrayout[arg2 - arg1]' #return
])

mod.generate ('lua')

# coding: utf-8
from inclua import *
import inclua.lua
import sys

mod = Generator ('teste')
mod.set_clang_args (['-I/usr/lib/clang/3.9.1/include'])
mod.add_header ('teste.h')

# teste das anotações
mod.scope ('Nice')
mod.rename ('getOi', 'oie')
# mod.rename ('union Outra', 'outra')

mod.note ('getAB', ['in', 'out', 'out'])
mod.note ('somaVet', ['array[arg2] in', 'size'])
mod.note ('somaVetAte0', ['array[_] in'])
mod.note ('range', ['array[arg3 - arg2] out', 'in', 'in'])
mod.note ('rangeAlloc', [
    'in',
    'in',
    'array[arg2 - arg1] out' #return
])
mod.note ('printaMatriz', ['array[arg2][arg3] in', 'size', 'size'])
mod.note ('printaMatrizQuadrada', ['array[arg2][arg2] in', 'size'])
mod.note ('geraAleatorios', ['size out', 'array[arg1] out'])

# mod.add_constant ('ZERO', 'ZERO')

mod.generate ('lua', len (sys.argv) > 1)

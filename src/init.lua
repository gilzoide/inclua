--[[
-- Copyright 2016-2017 Gil Barbosa Reis <gilzoide@gmail.com>
-- This file is part of Inclua.
--
-- Inclua is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- Inclua is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with Inclua.  If not, see <http://www.gnu.org/licenses/>.
--]]

local inclua = {}

inclua.Visitor = require 'inclua.visitor'
inclua.generate = require 'inclua.generate'
inclua.templates = require 'inclua.templates'
inclua.note = require 'inclua.note'

function inclua._test()
	print(inclua.INFO)
	local notes = {
		ignore_pattern = '^_.+',
		ignore = {'somaVet'},
		rename = {
			nome_feio = 'nome_bonito',
			COMO_VAI = 'como_vai',
		},
		constants = {
			version = '"1.0"',
		},
		defs = {
			nao_quero = 'ignore',
			native_func = 'native',
			swap = {'inout', 'inout'},
		}
	}
	local wrapper = inclua.generate('teste', 'lua', {"../../example/teste.h"}, {"-I/usr/lib/clang/3.9.1/include/"}, notes)
	print(wrapper)
end

for k, v in pairs(require 'inclua.info') do
	inclua[k] = v
end

return inclua

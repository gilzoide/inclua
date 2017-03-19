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

inclua.VERSION = '0.0.1'

inclua.Visitor = require 'inclua.visitor'

function inclua._test()
	V = inclua.Visitor()
	V:visitHeader("../../example/teste.h", {"-I/usr/lib/clang/3.9.1/include/"})
	for k, v in ipairs(V.enums) do
		print('Enum ' .. tostring(k), v.name, v.alias)
		for name, val in pairs(v.values) do
			print('  ' .. name, val)
		end
	end
	for k, v in ipairs(V.functions) do
		print('Function ' .. v.name, v.type.spelling)
	end
	for k, v in ipairs(V.records) do
		print('Record ' .. v.name, v.alias)
		for name, ty in pairs(v.type.fields) do
			print('  ' .. name, ty.spelling)
		end
	end
	for k, v in ipairs(V.globals) do
		print('Var ' .. v.name, v.type.spelling)
	end

	for k, v in pairs(V.allDefs) do
		if v.alias then
			print('Typedef ' .. v.alias, k)
		end
	end
end

return inclua

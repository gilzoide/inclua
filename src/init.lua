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

function inclua._test()
	V = inclua.Visitor()
	V:visitHeader("../../example/teste.h", {"-I/usr/lib/clang/3.9.1/include/"})
	for k, v in pairs(V.enums) do
		print('Enum ' .. tostring(k), v.alias or v.name)
		for name, val in pairs(v.values) do
			print('  ' .. name, val)
		end
	end
end

return inclua

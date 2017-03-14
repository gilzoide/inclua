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

local _visitHeader = require 'inclua.visitHeader'

local Visitor = {}
Visitor.__index = Visitor

function Visitor:visitHeader(header, clang_args)
	return _visitHeader(self, header, clang_args)
end

function Visitor:handleTypedef(alias, ty_hash)
	if self.allDefs[ty_hash] then
		self.allDefs[ty_hash].alias = alias
	end
end

function Visitor:handleEnum(hash, name)
	if self.enums[hash] == nil then
		local newEnum = {
			name = name,
			values = {},
		}
		self.enums[hash] = newEnum
		self.allDefs[hash] = newEnum
		table.insert(self.enums, newEnum)
	end
end

function Visitor:handleEnumConstant(hash, name, value)
	self.enums[hash].values[name] = value
end

function Visitor:handleFunction(name, ty)
	if self.functions[name] == nil then
		local newFunction = {
			name = name,
			type = ty,
		}
		self.functions[name] = newFunction
	end
end

function Visitor:handleRecord(name, ty)
	if self.records[name] == nil then
		local newRecord = {
			name = name,
			type = ty,
		}
		self.records[name] = newRecord
		self.allDefs[ty.hash] = newRecord
		table.insert(self.records, newRecord)
	end
end

return function()
	return setmetatable({
		enums = {},
		records = {},
		functions = {},
		-- All definitions, for Typedefs to work nicely
		allDefs = {},
	}, Visitor)
end

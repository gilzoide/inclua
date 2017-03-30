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

local cppVisitHeader = require 'inclua.visitHeader'

local Visitor = {}
Visitor.__index = Visitor

--- Visit a header, gathering information on its declarations.
--
-- @tparam string header Header file name
-- @tparam table clang_args Arguments passed to libclang on parsing
--
-- @return[1] true If everything went ok
-- @return[2] nil
-- @return[2] Error message
function Visitor:visitHeader(header, clang_args)
	if cppVisitHeader(self, header, clang_args) then
		return true
	else
		return nil, 'Error visiting "' .. header .. '"'
	end
end

function Visitor:__handleTypedef(alias, ty_hash)
	if self.allDefs[ty_hash] then
		self.allDefs[ty_hash].alias = alias
	end
end

function Visitor:__handleEnum(hash, ty)
	local name = ty.spelling
	if self.enums[hash] == nil then
		local newEnum = {
			name = name,
			type = ty,
			values = {},
		}
		self.enums[hash] = newEnum
		self.allDefs[hash] = newEnum
		table.insert(self.enums, newEnum)
	end
end

function Visitor:__handleEnumConstant(hash, name, value)
	self.enums[hash].values[name] = value
end

function Visitor:__handleFunction(name, ty)
	if self.functions[name] == nil then
		local newFunction = {
			name = name,
			type = ty,
		}
		self.functions[name] = newFunction
		table.insert(self.functions, newFunction)
	end
end

function Visitor:__handleRecord(ty)
	local name = ty.spelling
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

function Visitor:__handleVar(name, ty)
	local newGlobalVar = {
		name = name,
		type = ty,
	}
	self.globals[name] = newGlobalVar
	table.insert(self.globals, newGlobalVar)
end

function Visitor:__apply_notes(notes)
end

return function()
	return setmetatable({
		enums = {},
		records = {},
		functions = {},
		globals = {},
		-- All definitions, for Typedefs to work nicely
		allDefs = {},
	}, Visitor)
end

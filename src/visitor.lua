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

local path = require 'pl.path'
local tablex = require 'pl.tablex'
local filter = tablex.filter
local find_file = require 'inclua.find_file'

local cppVisitHeader = require 'inclua.visitHeader'
local note = require 'inclua.note'

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
	local header_path, err = find_file(header, clang_args)
	if not header_path then
		return nil, string.format("Couldn't find header file %q. Tried in %s", header, err)
	elseif cppVisitHeader(self, header_path, clang_args) then
		return true
	else
		return nil, 'Error visiting "' .. header .. '"'
	end
end

function Visitor:__handleTypedef(alias, ty_hash, underlying)
	if self.allDefs[ty_hash] then
		self.allDefs[ty_hash].name = alias
	else
		underlying.name = alias
	end
end

function Visitor:__handleEnum(hash, ty, parent_hash)
	local name = ty.name
	if self.enums[hash] == nil then
		local newEnum = {
			name = name,
			type = ty,
			values = {},
			parent = parent_hash and self.allDefs[parent_hash],
		}
		self.enums[hash] = newEnum
		self.allDefs[hash] = newEnum
		table.insert(self.enums, newEnum)
	end
end

function Visitor:__handleEnumConstant(hash, name, value)
	if self.allDefs[name] == nil then
		local newEnumConstant = {
			name = name,
			value = value,
		}
		table.insert(self.enums[hash].values, newEnumConstant)
		self.allDefs[name] = newEnumConstant
	end
end

function Visitor:__handleFunction(name, ty)
	if self.functions[name] == nil then
		local newFunction = {
			name = name,
			type = ty,
		}
		self.functions[name] = newFunction
		self.allDefs[name] = newFunction
		table.insert(self.functions, newFunction)
	end
end

function Visitor:__handleRecord(ty)
	local name = ty.name
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
	self.allDefs[name] = newGlobalVar
	table.insert(self.globals, newGlobalVar)
end

--- Apply notes to the known definitions
function Visitor:__apply_notes(notes)
	notes = note.process(notes)
	self.constants = notes.constants

	for _, def in pairs(self.allDefs) do
		-- apply ignores
		for _, ignore in ipairs(notes.ignore) do
			if def.name == ignore then
				def.notes = 'ignore'
				goto next_iter
			end
		end
		for _, patt in ipairs(notes.ignore_pattern) do
			if string.match(def.name, patt) then
				def.notes = 'ignore'
				goto next_iter
			end
		end
		-- apply renames
		for name, alias in pairs(notes.rename) do
			if def.name == name then
				def.alias = alias
				goto copy_notes
			end
		end
		for patt, repl in pairs(notes.rename_pattern) do
			local alias, nsubs = string.gsub(def.name, patt, repl)
			if nsubs > 0 then
				def.alias = alias
				goto copy_notes
			end
		end
		::copy_notes::
		-- just copy notes (`nil` if there is none)
		def.notes = notes.defs[def.name]

		::next_iter::
	end
end

--- Filter out ignored definitions
function Visitor:__apply_ignores()
	-- ignore filter
	local function is_ignore(t) return t.notes ~= 'ignore' end
	local function filter_ignore(t) return filter(t, is_ignore) end

	self.enums = filter_ignore(self.enums)
	self.records = filter_ignore(self.records)
	self.functions = filter_ignore(self.functions)
	self.constants = filter_ignore(self.constants)
	self.globals = filter_ignore(self.globals)
end

return function()
	return setmetatable({
		enums = {},
		records = {},
		functions = {},
		globals = {},
		-- All definitions, for Typedefs and notes to work nicely
		allDefs = {},
	}, Visitor)
end

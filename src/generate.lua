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

local templates = require 'inclua.templates'
local Visitor = require 'inclua.visitor'
local info = require 'inclua.info'

--- Generate the wrapper module code.
--
-- @raise If target language template is not found.
--
-- @tparam string module_name Name of the generate module
-- @tparam string language Target language
-- @tparam table headers Header files to be parsed
-- @tparam table clang_args Arguments passed to libclang on parsing
-- @tparam table notes Extra notes on the information gathered on the headers
--
-- @treturn string Wrapper code
local function generate(module_name, language, headers, clang_args, notes)
	local language_template = assert(templates.load(language))

	-- visit the wanted headers
	local V = Visitor()
	for _, header in ipairs(headers) do
		assert(V:visitHeader(header, clang_args))
	end
	-- apply notes
	V:__apply_notes(notes)

	return language_template{
		module_name = module_name,
		enums = V.enums,
		records = V.records,
		functions = V.functions,
		globals = V.globals,
		info = info,
	}
end

return generate

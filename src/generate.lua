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

local yaml = require 'lyaml'
local tablex = require 'pl.tablex'
local Set = require 'pl.Set'

local templates = require 'inclua.templates'
local Visitor = require 'inclua.visitor'
local info = require 'inclua.info'
local find_file = require 'inclua.find_file'
local note = require 'inclua.note'

local generate = {}

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
function generate.generate(module_name, language, headers, clang_args, notes)
	local language_template = assert(templates.load(language))

	-- visit the wanted headers
	local V = Visitor()
	for _, header in ipairs(headers) do
		assert(V:visitHeader(header, clang_args))
	end
	-- apply notes
	V:__apply_notes(notes)
	V:__apply_ignores()

	local ret = language_template{
		module_name = module_name,
		headers = headers,
		enums = V.enums,
		records = V.records,
		functions = V.functions,
		constants = V.constants,
		globals = V.globals,
		info = info,
	}
	return ret
end

-- special headers on the header configuration section
local header_conf_keys = Set{'module', 'clang_args', 'headers', 'include',
		'ignore', 'ignore_pattern', 'rename', 'rename_pattern', 'constants'}

--- Process a single YAML configuration file.
--
-- @local
local function _include_yaml(result, filename, clang_args)
	local filepath, err = find_file(filename, clang_args)
	assert(filepath, string.format("Couldn't find YAML file %q. Tried in %s", filename, err))

	local contents = assert(io.open(filepath, "r")):read('*a')
	contents, err = yaml.load(contents, {all = true})
	assert(contents, string.format("YAML error on file %q: %s", filepath, err))
	
	local header_conf = contents[1]
	if not result.module then
		result.module = assert(header_conf.module, "Toplevel YAML document should have a 'module' field")
	end

	-- recurse YAML configurations
	if header_conf.include then
		for _, f in ipairs(header_conf.include) do
			_include_yaml(result, f, clang_args)
		end
	end
	if header_conf.clang_args then tablex.insertvalues(clang_args, header_conf.clang_args) end
	if header_conf.headers then tablex.insertvalues(result.headers, header_conf.headers) end
	if header_conf.ignore then tablex.insertvalues(result.notes.ignore, header_conf.ignore) end
	if header_conf.ignore_pattern then tablex.insertvalues(result.notes.ignore_pattern, header_conf.ignore_pattern) end
	if header_conf.rename then tablex.update(result.notes.rename, header_conf.rename) end
	if header_conf.rename_pattern then tablex.update(result.notes.rename_pattern, header_conf.rename_pattern) end
	if header_conf.constants then tablex.update(result.notes.constants, header_conf.constants) end

	local definitions_conf
	if contents[2] then
		definitions_conf = contents[2]
	else
		definitions_conf = tablex.difference(header_conf, header_conf_keys)
	end
	for k, v in pairs(definitions_conf) do
		result.notes.defs[k] = v
	end
end

--- Generate the wrapper module using configuration from a YAML file.
--
-- @tparam string filename  Root YAML file name
-- @tparam string language  Target language
-- @tparam table clang_args Arguments passed to libclang on parsing
--
-- @treturn string Wrapper code
function generate.from_yaml(filename, language, clang_args)
	local result = {headers = {}, notes = note.empty()}
	_include_yaml(result, filename, clang_args)

	return generate.generate(result.module, language, result.headers, clang_args, result.notes)
end

return generate

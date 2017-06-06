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

local lpeg = require 'lpeglabel'
local re = require 'relabel'
local tablex = require 'pl.tablex'

local note = {}

-- Parser errors
local parseErrors = {}
parseErrors[0] = "PEG couldn't parse"
parseErrors.PegError = 0
local function addError(label, msg)
	table.insert(parseErrors, msg)
	parseErrors[label] = #parseErrors
end
addError('InvalidTopLevel', "Invalid top level note")
addError('InvalidArgument', "Invalid argument note")
re.setlabels(parseErrors)


note.toplevel_grammar = re.compile[[
S <- { 'ignore' / 'opaque' / 'scope' / 'native' } !. / %{InvalidTopLevel}
]]

note.arguments_grammar = re.compile[=[
S <- {| Array / Size / Inout |} !. / %{InvalidArgument}

Inout <- {:kind: { In Out } :}
       / {:kind: In :} Default?
	   / {:kind: Out :} Free?
In <- { 'in' }
Out <- { 'out' }
Free <- %s+ "free" %s* "=" %s* {:free: Identifier :}
Default <- %s* "=" %s* {:default: .+ :}
Identifier <- { .+ }

Size <- {:kind: {~ "size" (" " In / " " Out / "" -> " in" ) ~} :}

Array <- "array" {:dims: {| Dimension+ |} :} " " {:kind: (In / Out) -> 'array %1' :}
Dimension <- "[" { [^]]+ } "]"
]=]

local function parse(grammar, n)
	local res, label, suf = grammar:match(n)
	if res then
		return res
	else
		local whereErr = #n - #suf
		local lin, col = re.calcline(n, whereErr)
		return nil, string.format("%s at %d:%d (%s)", parseErrors[label], lin, col, n)
	end
end

--- Parse a toplevel note.
function note.parse_toplevel(n)
	return parse(note.toplevel_grammar, n)
end
--- Parse a argument note.
function note.parse_argument(n)
	return parse(note.arguments_grammar, n)
end

--- Ensure `t[field]` is a table.
--
-- This is used to normalize some fields in the notes.
--
-- @local
local function ensure_table(t, field)
	return type(t[field]) == 'table' and t[field] or {t[field]}
end

--- Process notes, validating and getting info for them.
--
-- @raise If there are invalid notes.
function note.process(notes)
	local result = {}
	result.ignore = ensure_table(notes, 'ignore')
	result.ignore_pattern = ensure_table(notes, 'ignore_pattern')
	result.rename = ensure_table(notes, 'rename')
	result.rename_pattern = ensure_table(notes, 'rename_pattern')
	result.constants = ensure_table(notes, 'constants')
	result.defs = tablex.map(function(v)
		local ty = type(v)
		if ty == 'string' then
			return assert(note.parse_toplevel(v))
		elseif ty == 'table' then
			return tablex.imap(function(n)
				return assert(note.parse_argument(n))
			end, v)
		end
	end, notes.defs or {})

	return result
end

return note

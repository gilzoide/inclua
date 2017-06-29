#!/usr/bin/env lua
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

local inclua = require 'inclua'

-- CLI arguments stuff
local argmatcher = require 'argmatcher'
local parser = argmatcher.new()

local opts = {
	LANGUAGE = "lua",
}
parser:on{
	"-o", "--output",
	arg = "OUTPUT",
	description = "output file (default: stdout)",
	store = opts,
}
parser:on{
	"-l", "--language",
	arg = "LANGUAGE",
	description = "binding target language (default: lua)",
	store = opts,
}
parser:on{
	"-d", "--dependencies",
	description = "find which files the input depends on, useful for build systems dependency management",
	store = opts,
}
parser:stop_on{
	"-v", "--version",
	description = "prints program version and exit",
	callback = function() print("Inclua version " .. inclua.VERSION); os.exit() end,
}
local usage = [[
Usage: inclua [-o OUTPUT] [-l LANGUAGE] input [clang-args...]
       inclua [-o OUTPUT] [-d] input [clang-args...]
       inclua (-h|-v|-u)]]
parser:stop_on{
	"-u", "--usage",
	description = "prints program usage and exit",
	callback = function() print(usage); os.exit() end,
}
parser:stop_on{
	"-h", "--help",
	description = "show this help message and exit",
	callback = function() parser:show_help(usage .. [[


Inclua is a binding code generator, that binds (for now, only) C to Lua.

Arguments:
  input         input YAML configuration file
  clang-args    arguments to clang parser, useful for
                "-Dname"/"-Dname=val" macros and "-Iinclude_directory"
                flags (which will be used by inclua to look for the
                headers)]],
"Any bugs should be reported to <gilzoide@gmail.com>"); os.exit() end,
}

local args = parser:parse()
assert(#args > 0, "Missing input argument is required")

if opts.OUTPUT then
	opts.OUTPUT = assert(io.open(opts.OUTPUT, "w"))
else
	opts.OUTPUT = io.stdout
end

local input = table.remove(args, 1)
local operation = inclua.generate[opts['-d'] and 'dependencies_from_yaml' or 'from_yaml']
opts.OUTPUT:write(operation(input, args, opts.LANGUAGE))

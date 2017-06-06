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

local lapp = require 'pl.lapp'
lapp.slack = true
local pretty = require 'pl.pretty'

local inclua = require 'inclua'

local args = lapp [[
Inclua Copyright (c) 2016-2017 Gil Barbosa Reis.
Inclua is a binding code generator, that binds (for now, only) C to Lua.

Generating wrappers:
  -h,--help              show this help message and exit
  -v,--version           prints program version
  -o,--output (default stdout)    output wrapper file
  -l,--language (string)  binding target language
  <input> (string)                input YAML configuration file
  <clang_arg...> (string default '')           arguments to clang parser, useful for
                          "-Dname"/"-Dname=val" macros and "-Iinclude_directory"
                          flags (which will be used by inclua to look for the
                          headers)

Any bugs should be reported to <gilzoide@gmail.com>
]]

pretty.dump(args)

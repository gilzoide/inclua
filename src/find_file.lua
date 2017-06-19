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

--- Find a file, searching from "." and any directory specified by "-I" flags.
--
-- @param filename The desired file name
-- @param clang_args Command line arguments given to inclua, and that will be
--        passed unchanged to clang
--
-- @return[1] Found file path
-- @return[2] nil
-- @return[2] List of paths tried
local function find_file(filename, clang_args)
	local search_paths = tablex.filter(clang_args, function(p) return p:sub(1, 2) == "-I" end)
	search_paths = tablex.imap(function(p) return p:sub(3) end, search_paths)
	table.insert(search_paths, 1, ".")
	for _, prefix in ipairs(search_paths) do
		local file_path = path.join(prefix, filename)
		if path.isfile(file_path) then
			return file_path
		end
	end
	return nil, '("' .. table.concat(search_paths, "\", \"") .. '")'
end

return find_file

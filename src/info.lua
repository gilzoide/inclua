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

local molde = require 'molde'
local templates = require 'inclua.templates'

local info = {}

--- Module version 0.0.1
info.VERSION = '0.0.1'

--- Executable info string
info.INFO = string.format([[inclua version %s
Template path: %s]], info.VERSION, templates.PATH)

local notice_lines = {
    "This file was automatically generated by inclua " .. info.VERSION,
    "",
    "The Inclua team hopes this file was accurately generated,",
    "that it will be useful and will never give a SEGFAULT.",
    "This file is distributed without any warranty.",
    "Fell free to change and distribute it, just be careful.",
}
local notice_template = molde.load[[
{{ opening or '' }}
{{ table.concat(notice_lines, '\n' .. (middle or '')) }}
{{ closing or '' }}
]]

--- Generates the notice to be used in generated source files.
--
-- @param[opt] opening String that opens the notice, useful for comment blocks
-- @param[optchain] middle String that prefix each line
-- @param[optchain] closing String that closes the notice, useful for comment
-- blocks
--
-- @return Notice string
function info.gen_notice(opening, middle, closing)
	return notice_template{
		opening = opening,
		middle = middle,
		closing = closing,
		notice_lines = notice_lines,
	}
end

--- Notice for generated source files, txt version.
info.NOTICE = info.gen_notice()

--- Notice for generated source files, C/C++ comment block version.
info.C_NOTICE = info.gen_notice('/* ', ' * ', '\n */')

--- Notice for generated source files, shell/python comments version.
info.SHELL_NOTICE = info.gen_notice('# ', '# ')

return info
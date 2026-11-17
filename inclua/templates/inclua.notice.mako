<%!
from inclua import notice_lines
%>
<%def name="c_notice()" filter="trim">
/*
% for line in notice_lines:
 * ${line}
% endfor 
 */
</%def>

<%def name="lua_notice()" filter="trim">
--[[
% for line in notice_lines:
-- ${line}
% endfor 
--]]
</%def>

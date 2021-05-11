<%!
import re

from c_api_extract import typed_declaration

from inclua.namespace import canonicalize
%>

<%namespace file="inclua.notice.mako" import="lua_notice"/>

<%def name="def_var(d)" filter="trim">
  ${typed_declaration(d['type']['spelling'], d['name'])};
</%def>

<%def name="def_record(d)" filter="trim">
  <%    
    kind = d['kind']
    typedef = d['name'] if not d['spelling'].startswith(kind) else ""
    fields = d['fields'] or ""
  %>
${typedef and "typedef "}${kind} ${d['name']}${fields and " {\n"}\
  % for f in fields:
  ${typed_declaration(f[0]['spelling'], f[1])};
  % endfor
${fields and "}"}${typedef and " " + typedef};
</%def>

<%def name="def_enum(d)" filter="trim">
  <% typedef = d['name'] if not d['spelling'].startswith('enum') else '' %>
${typedef and "typedef "}enum ${d['name']} {
  % for key, value in d['values']:
  ${key} = ${value},
  % endfor
}${typedef and " " + typedef};
</%def>

<%def name="def_function(d)" filter="trim">
  ${d['return_type']['spelling']} ${d['name']}(${", ".join(typed_declaration(a[0]['spelling'], a[1]) for a in d['arguments'])});
</%def>

<%def name="def_typedef(d)" filter="trim">
  typedef ${typed_declaration(d['type']['spelling'], d['name'])};
</%def>

${lua_notice()}

local ffi = require 'ffi'

ffi.cdef[=[
% for d in definitions:
  % if d['kind'] == 'var':
${def_var(d)}
  % elif d['kind'] in ('struct', 'union'):
${def_record(d)}
  % elif d['kind'] == 'enum':
${def_enum(d)}
  % elif d['kind'] == 'function':
${def_function(d)}
  % elif d['kind'] == 'typedef':
${def_typedef(d)}
  % endif 
% endfor
]=]

local c_lib = ffi.load("${module_name}")

local lua_lib = setmetatable({ c_lib = c_lib }, { __index = c_lib })
% for metatype in metatypes:
lua_lib.${metatype.unprefixed} = ffi.metatype("${metatype.spelling}", {
  __name = "${metatype.name}",
  % if metatype.destructor:
    __gc = c_lib.${metatype.destructor['name']},
  % endif
  % for method in metatype.native_methods:
    % if method[0].startswith('__'):
  ${method[0]} = ${method[1]},
    % endif
  % endfor
  % if metatype.methods or metatype.native_methods:
  __index = {
<%    replace_method_name_re = re.compile('_?' + metatype.unprefixed) %>\
    % for method in metatype.methods:
    ${replace_method_name_re.sub('', canonicalize(method['name'], namespace_prefixes), count=1).lstrip('_')} = c_lib.${method['name']},
    % endfor
    % for method in metatype.native_methods:
      % if not method[0].startswith('__'):
    ${method[0]} = ${method[1]},
      % endif
    % endfor
  }
  % endif
})
% endfor
% if namespace_prefixes:
<%
    prefixed = {}
    for d in definitions:
        name = d['name']
        if d['kind'] in ('typedef', 'enum', 'struct', 'union') or name in prefixed:
            continue
        canonicalized = canonicalize(name, namespace_prefixes)
        if name != canonicalized:
            prefixed[name] = canonicalized
%>
  % for name, unprefixed in prefixed.items():
lua_lib.${unprefixed} = lua_lib.${name}
  % endfor
% endif
return lua_lib\

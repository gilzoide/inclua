<%!
import re

from c_api_extract import typed_declaration
%>

<%namespace file="inclua.notice.mako" import="lua_notice"/>

<%def name="def_var(d)" filter="trim">
  ${typed_declaration(d.type.spelling, d.name)};
</%def>

<%def name="def_record(d)" filter="trim">
  <%    
    kind = d.kind
    typedef = d.name if not d.spelling.startswith(kind) else ""
    fields = d.fields or ""
  %>
${typedef and "typedef "}${kind} ${d.name}${fields and " {\n"}\
  % for f in fields:
  ${typed_declaration(f.type.spelling, f.name)};
  % endfor
${fields and "}"}${typedef and " " + typedef};
</%def>

<%def name="def_enum(d)" filter="trim">
  <% typedef = d.name if not d.spelling.startswith('enum') else '' %>
  ${typedef and "typedef "}enum ${d.name} {
  % for value in d.values:
  ${value.name} = ${value.value},
  % endfor
}${typedef and " " + typedef};
</%def>

<%def name="def_function(d)" filter="trim">
  ${d.return_type.spelling} ${d.name}(${", ".join(typed_declaration(a.type.spelling, a.name) for a in d.arguments)});
</%def>

<%def name="def_typedef(d)" filter="trim">
  typedef ${typed_declaration(d.type.spelling, d.name)};
</%def>

${lua_notice()}

local ffi = require 'ffi'

ffi.cdef[=[
% for d in definitions:
  % if d.kind == 'var':
${def_var(d)}
  % elif d.is_record():
${def_record(d)}
  % elif d.kind == 'enum':
${def_enum(d)}
  % elif d.kind == 'function':
${def_function(d)}
  % elif d.kind == 'typedef':
${def_typedef(d)}
  % endif 
% endfor
]=]

local c_lib = ffi.load('${module_name}')

local lua_lib = setmetatable({ c_lib = c_lib }, { __index = c_lib })
% for t in oop.iter_types():
<%
    unprefixed_name = oop.get_unprefixed_name(t)
    methods = oop.get_methods(t)
    native_methods = oop.get_native_methods(t)
    destructor = oop.get_destructor(t)
%>
lua_lib.${unprefixed_name} = ffi.metatype('${t.spelling}', {
  __name = '${t.name}',
  % if destructor:
  __gc = c_lib.${destructor.name},
  % endif
  % for method_name, method_impl in native_methods:
    % if method_name.startswith('__'):
  ${method_name} = ${method_impl},
    % endif
  % endfor
  % if methods or native_methods:
  __index = {
<%    replace_method_name_re = re.compile('_?' + unprefixed_name) %>\
    % for method in methods:
    ${replace_method_name_re.sub('', canonicalize(method.name), count=1).lstrip('_')} = c_lib.${method.name},
    % endfor
    % for method_name, method_impl in native_methods:
      % if not method_name.startswith('__'):
    ${method_name} = ${method_impl},
      % endif
    % endfor
  },
  % endif
})
% endfor
% if namespace_prefixes:
<%
    prefixed = {}
    for d in definitions:
        name = d.name
        if d.kind in ('typedef', 'enum', 'struct', 'union') or name in prefixed:
            continue
        canonicalized = canonicalize(name)
        if name != canonicalized:
            prefixed[name] = canonicalized
%>
  % for name, unprefixed in prefixed.items():
lua_lib.${unprefixed} = lua_lib.${name}
  % endfor
% endif
return lua_lib\

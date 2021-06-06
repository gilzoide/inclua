<%namespace file="inclua.notice.mako" import="c_notice"/>

<% 
    REGISTER_NAME = 'inclua_{}_register'
    CONSTRUCTOR_NAME = 'inclua_{}_constructor'
    DESTRUCTOR_NAME = 'inclua_{}_destructor'
%>

<%def name="def_metatype(m)" filter="trim">
<%
    constructor_name = CONSTRUCTOR_NAME.format(m.name)
    destructor_name = DESTRUCTOR_NAME.format(m.name)
%>
void *${constructor_name}(godot_object *go, void *method_data) {
    ${m.spelling} *obj = (${m.spelling} *) api->godot_alloc(sizeof(${m.spelling}));
    *obj = {};
    return obj;
}

void ${destructor_name}(godot_object *go, void *method_data, void *obj) {
    % if m.destructor:
    ${m.destructor['name']}(obj);
    % endif
    api->godot_free(obj);
}

void ${REGISTER_NAME.format(m.name)}(void *p_handle) {
    godot_instance_create_func create_func = { &${constructor_name}, NULL, NULL };
    godot_instance_destroy_func destroy_func = { &${destructor_name}, NULL, NULL };
    nativescript_api->godot_nativescript_register_class(
        p_handle, "${m.unprefixed}", "Reference",
        create_func, destroy_func
    );
}
</%def>

${c_notice()}

/*
 * This code is C++17
 */

#ifndef INCLUA_GDNATIVE_HPP
#define INCLUA_GDNATIVE_HPP

#include <cstring>

#include <gdnative_api_struct.gen.h>

#include "${header}"

const godot_gdnative_core_api_struct *api = NULL;
const godot_gdnative_ext_nativescript_api_struct *nativescript_api = NULL;

% for m in metatypes:
${def_metatype(m)}
% endfor

% for d in definitions:
% endfor

extern "C" {

///////////////////////////////////////////////////////////////////////////////
// API initialization
///////////////////////////////////////////////////////////////////////////////
GDN_EXPORT void godot_gdnative_init(godot_gdnative_init_options *p_options) {
    api = p_options->api_struct;
    // Now find our extensions.
    for(int i = 0; i < api->num_extensions; i++) {
        switch(api->extensions[i]->type) {
            case GDNATIVE_EXT_NATIVESCRIPT: {
                nativescript_api = (godot_gdnative_ext_nativescript_api_struct *) api->extensions[i];
            }; break;
            default: break;
        }
    }
}

GDN_EXPORT void godot_gdnative_terminate(godot_gdnative_terminate_options *p_options) {
    nativescript_api = NULL;
    api = NULL;
}

GDN_EXPORT void godot_nativescript_init(void *p_handle) {
% for m in metatypes:
    ${REGISTER_NAME.format(m.name)}(p_handle);
% endfor

% for d in definitions:
% endfor
}

}
#endif

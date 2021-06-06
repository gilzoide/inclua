<%namespace file="inclua.notice.mako" import="c_notice"/>

<% 
    REGISTER_NAME = 'inclua_{}_register'
    CONSTRUCTOR_NAME = 'inclua_{}_constructor'
    DESTRUCTOR_NAME = 'inclua_{}_destructor'
    GETTER_NAME = 'inclua_get_{0}_{1}'
%>

<%def name="def_metatype(m)" filter="trim">
    <%def name="def_getter(p)" filter="trim">
GDCALLINGCONV godot_variant ${GETTER_NAME.format(m.name, p)}(godot_object *go, void *method_data, void *data) {
    ${m.spelling} *obj = (${m.spelling} *) data;
    return inclua_variant(obj->${p});
}
    </%def>
<%
    class_name = m.unprefixed
    constructor_name = CONSTRUCTOR_NAME.format(m.name)
    destructor_name = DESTRUCTOR_NAME.format(m.name)
%>
GDCALLINGCONV void *${constructor_name}(godot_object *go, void *method_data) {
    ${m.spelling} *obj = (${m.spelling} *) api->godot_alloc(sizeof(${m.spelling}));
    *obj = {};
    return obj;
}

GDCALLINGCONV void ${destructor_name}(godot_object *go, void *method_data, void *obj) {
    % if m.destructor:
    ${m.destructor['name']}(obj);
    % endif
    api->godot_free(obj);
}

% for prop_type, prop_name in m.fields:
${def_getter(prop_name)}
% endfor

void ${REGISTER_NAME.format(m.name)}(void *p_handle) {
    godot_instance_create_func create_func = { &${constructor_name}, NULL, NULL };
    godot_instance_destroy_func destroy_func = { &${destructor_name}, NULL, NULL };
    nativescript_api->godot_nativescript_register_class(
        p_handle, "${class_name}", "Reference",
        create_func, destroy_func
    );

    % for prop_type, prop_name in m.fields:
    {
        godot_property_attributes attr = { GODOT_METHOD_RPC_MODE_DISABLED };
        godot_property_get_func getter = { &${GETTER_NAME.format(m.name, prop_name)}, NULL, NULL };
        godot_property_set_func setter = { NULL, NULL, NULL };
        nativescript_api->godot_nativescript_register_property(
            p_handle, "${class_name}", "${prop_name}",
            &attr, setter, getter
        );

    }
    % endfor
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

godot_variant inclua_variant(bool b) {
    godot_variant var;
    api->godot_variant_new_bool(&var, b);
    return var;
}
godot_variant inclua_variant(uint64_t u) {
    godot_variant var;
    api->godot_variant_new_uint(&var, u);
    return var;
}
godot_variant inclua_variant(int64_t i) {
    godot_variant var;
    api->godot_variant_new_int(&var, i);
    return var;
}
godot_variant inclua_variant(godot_real i) {
    godot_variant var;
    api->godot_variant_new_real(&var, i);
    return var;
}
godot_variant inclua_variant(const char *s) {
    godot_string gs = api->godot_string_chars_to_utf8(s);
    godot_variant var;
    api->godot_variant_new_string(&var, &gs);
    api->godot_string_destroy(&gs);
    return var;
}

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

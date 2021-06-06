<%namespace file="inclua.notice.mako" import="c_notice"/>

<% 
    REGISTER_NAME = '{}_register'
    CONSTRUCTOR_NAME = '{}_constructor'
    DESTRUCTOR_NAME = '{}_destructor'
    SETTER_NAME = '{0}_set_{1}'
    GETTER_NAME = '{0}_get_{1}'
%>

<%def name="def_metatype(m)" filter="trim">
    <%def name="def_getter(p, t)" filter="trim">
INCLUA_DECL GDCALLINGCONV godot_variant ${GETTER_NAME.format(m.name, p)}(godot_object *go, void *method_data, void *data) {
    ${m.spelling} *obj = (${m.spelling} *) data;
    return to_variant(obj->${p});
}
    </%def>
    <%def name="def_setter(p, t)" filter="trim">
INCLUA_DECL GDCALLINGCONV void ${SETTER_NAME.format(m.name, p)}(godot_object *go, void *method_data, void *data, godot_variant *var) {
    ${m.spelling} *obj = (${m.spelling} *) data;
    % if t['base'] == 'char' and t.get('pointer'):
        % if len(t['pointer']) == 1:
    if (obj->${p}) {
        free((void *) obj->${p});
    }
    StringHelper gs = var;
    obj->${p} = strndup(gs.str(), gs.size());
        % elif len(t['pointer']) == 2:
    // TODO: PoolStringArray
        % endif
    % else:
    obj->${p} = from_variant<${t['spelling']}>(var);
    % endif
}
    </%def>
<%
    class_name = m.unprefixed
    constructor_name = CONSTRUCTOR_NAME.format(m.name)
    destructor_name = DESTRUCTOR_NAME.format(m.name)
%>
INCLUA_DECL GDCALLINGCONV void *${constructor_name}(godot_object *go, void *method_data) {
    ${m.spelling} *obj = (${m.spelling} *) api->godot_alloc(sizeof(${m.spelling}));
    *obj = {};
    return obj;
}

INCLUA_DECL GDCALLINGCONV void ${destructor_name}(godot_object *go, void *method_data, void *data) {
    ${m.spelling} *obj = (${m.spelling} *) data;
    % if m.destructor:
    ${m.destructor['name']}(obj);
    % endif
    api->godot_free(obj);
}

% for prop_type, prop_name in m.fields:
${def_setter(prop_name, prop_type)}
${def_getter(prop_name, prop_type)}
% endfor

INCLUA_DECL void ${REGISTER_NAME.format(m.name)}(void *p_handle) {
    godot_instance_create_func create_func = { &${constructor_name}, NULL, NULL };
    godot_instance_destroy_func destroy_func = { &${destructor_name}, NULL, NULL };
    nativescript_api->godot_nativescript_register_class(
        p_handle, "${class_name}", "Reference",
        create_func, destroy_func
    );

    % for prop_type, prop_name in m.fields:
    {
        godot_property_attributes attr = { GODOT_METHOD_RPC_MODE_DISABLED };
        attr.usage = GODOT_PROPERTY_USAGE_DEFAULT;
        godot_property_get_func getter = { &${GETTER_NAME.format(m.name, prop_name)}, NULL, NULL };
        godot_property_set_func setter = { &${SETTER_NAME.format(m.name, prop_name)}, NULL, NULL };
        nativescript_api->godot_nativescript_register_property(
            p_handle, "${class_name}", "${prop_name}",
            &attr, setter, getter
        );

    }
    % endfor
}
</%def>

${c_notice()}

#ifndef INCLUA_GDNATIVE_HPP
#define INCLUA_GDNATIVE_HPP

#include <cstring>

#include <gdnative_api_struct.gen.h>

#include "${header}"

#ifndef INCLUA_DECL
    #ifdef INCLUA_STATIC
        #define INCLUA_DECL static
    #else
        #define INCLUA_DECL extern
    #endif
#endif

const godot_gdnative_core_api_struct *api = NULL;
const godot_gdnative_ext_nativescript_api_struct *nativescript_api = NULL;

namespace inclua {

///////////////////////////////////////////////////////////////////////////////
// Helper classes
///////////////////////////////////////////////////////////////////////////////
class StringHelper {
public:
    StringHelper(const char *s) : gcs_valid(false) {
        gs = api->godot_string_chars_to_utf8(s);
    }
    StringHelper(const godot_variant *var) : gcs_valid(false) {
        gs = api->godot_variant_as_string(var);
    }
    ~StringHelper() {
        if (gcs_valid) {
            api->godot_char_string_destroy(&gcs);
        }
        api->godot_string_destroy(&gs);
    }
    const char *str() {
        if (!gcs_valid) {
            gcs = api->godot_string_utf8(&gs);
            gcs_valid = true;
        }
        return api->godot_char_string_get_data(&gcs);
    }
    godot_int size() const {
        return api->godot_string_length(&gs);
    }
    operator godot_string *() {
        return &gs;
    }
private:
    godot_string gs;
    godot_char_string gcs;
    bool gcs_valid;
};

///////////////////////////////////////////////////////////////////////////////
// Data -> Variant
///////////////////////////////////////////////////////////////////////////////
INCLUA_DECL godot_variant to_variant(bool b) {
    godot_variant var;
    api->godot_variant_new_bool(&var, b);
    return var;
}
INCLUA_DECL godot_variant to_variant(uint64_t u) {
    godot_variant var;
    api->godot_variant_new_uint(&var, u);
    return var;
}
INCLUA_DECL godot_variant to_variant(int64_t i) {
    godot_variant var;
    api->godot_variant_new_int(&var, i);
    return var;
}
INCLUA_DECL godot_variant to_variant(godot_real i) {
    godot_variant var;
    api->godot_variant_new_real(&var, i);
    return var;
}
INCLUA_DECL godot_variant to_variant(const char *s) {
    StringHelper gs = s;
    godot_variant var;
    api->godot_variant_new_string(&var, gs);
    return var;
}

///////////////////////////////////////////////////////////////////////////////
// Variant -> Data
///////////////////////////////////////////////////////////////////////////////
template<typename T>
INCLUA_DECL T from_variant(const godot_variant *var) {
    godot_object *go = api->godot_variant_as_object(var);
    void *data = nativescript_api->godot_nativescript_get_userdata(go);
    return *((T *) data);
}
template<> bool from_variant(const godot_variant *var) {
    return api->godot_variant_as_bool(var);
}
template<> uint64_t from_variant(const godot_variant *var) {
    return api->godot_variant_as_uint(var);
}
template<> int64_t from_variant(const godot_variant *var) {
    return api->godot_variant_as_int(var);
}
template<> double from_variant(const godot_variant *var) {
    return api->godot_variant_as_real(var);
}

///////////////////////////////////////////////////////////////////////////////
// Classes
///////////////////////////////////////////////////////////////////////////////
% for m in metatypes:
${def_metatype(m)}
% endfor

% for d in definitions:
% endfor

} // namespace inclua

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
    inclua::${REGISTER_NAME.format(m.name)}(p_handle);
% endfor

% for d in definitions:
% endfor
}

} // extern "C"
#endif

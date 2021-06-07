<%namespace file="inclua.notice.mako" import="c_notice"/>

<% 
    REGISTER_NAME = '{}_register'
    CONSTRUCTOR_NAME = '{}_constructor'
    DESTRUCTOR_NAME = '{}_destructor'
    SETTER_NAME = '{0}_set_{1}'
    GETTER_NAME = '{0}_get_{1}'

    def godot_variant_type(t):
        if t.kind == 'bool':
            return 'GODOT_VARIANT_TYPE_BOOL'
        elif t.is_integral():
            return 'GODOT_VARIANT_TYPE_INT'
        elif t.is_floating_point():
            return 'GODOT_VARIANT_TYPE_REAL'
        elif t.is_string():
            return 'GODOT_VARIANT_TYPE_STRING'
        # TODO: array and pool arrays
        else:
            return 'GODOT_VARIANT_TYPE_OBJECT'
%>

<%def name="def_record(d)" filter="trim">
    <%def name="def_getter(f)" filter="trim">
INCLUA_DECL GDCALLINGCONV godot_variant ${GETTER_NAME.format(d.name, f.name)}(godot_object *go, void *method_data, void *data) {
    ${d.spelling} *obj = (${d.spelling} *) data;
    % if f.type.is_string():
    return string_to_variant(obj->${f.name});
    % else:
    return to_variant(obj->${f.name});
    % endif
}
    </%def>
    <%def name="def_setter(f)" filter="trim">
INCLUA_DECL GDCALLINGCONV void ${SETTER_NAME.format(d.name, f.name)}(godot_object *go, void *method_data, void *data, godot_variant *var) {
    ${d.spelling} *obj = (${d.spelling} *) data;
    % if f.type.is_string():
    if (obj->${f.name}) {
        free((void *) obj->${f.name});
    }
    StringHelper gs = var;
    obj->${f.name} = strndup(gs.str(), gs.size());
    % elif f.type.is_string_array():
    // TODO: PoolStringArray
    % else:
    obj->${f.name} = from_variant<${f.type.spelling}>(var);
    % endif
}
    </%def>
<%
    class_name = oop.unprefixed.get(d.name, d.name)
    constructor_name = CONSTRUCTOR_NAME.format(d.name)
    destructor_name = DESTRUCTOR_NAME.format(d.name)
%>
INCLUA_DECL GDCALLINGCONV void *${constructor_name}(godot_object *go, void *method_data) {
    ${d.spelling} *obj = (${d.spelling} *) api->godot_alloc(sizeof(${d.spelling}));
    *obj = {};
    return obj;
}

INCLUA_DECL GDCALLINGCONV void ${destructor_name}(godot_object *go, void *method_data, void *data) {
    ${d.spelling} *obj = (${d.spelling} *) data;
    % if oop.destructor.get(d.name):
    ${oop.destructor[d.name].name}(obj);
    % endif
    api->godot_free(obj);
}

% for f in d.fields:
${def_setter(f)}
${def_getter(f)}
% endfor

INCLUA_DECL void ${REGISTER_NAME.format(d.name)}(void *p_handle) {
    godot_instance_create_func create_func = { &${constructor_name}, NULL, NULL };
    godot_instance_destroy_func destroy_func = { &${destructor_name}, NULL, NULL };
    nativescript_api->godot_nativescript_register_class(
        p_handle, "${class_name}", "Reference",
        create_func, destroy_func
    );

    % for f in d.fields:
    {
        godot_property_attributes attr = {
            GODOT_METHOD_RPC_MODE_DISABLED,
            ${godot_variant_type(f.type)},
            GODOT_PROPERTY_HINT_NONE,
            godot_string(),
            GODOT_PROPERTY_USAGE_DEFAULT,
        };
        godot_property_get_func getter = { &${GETTER_NAME.format(d.name, f.name)}, NULL, NULL };
        godot_property_set_func setter = { &${SETTER_NAME.format(d.name, f.name)}, NULL, NULL };
        nativescript_api->godot_nativescript_register_property(
            p_handle, "${class_name}", "${f.name}",
            &attr, setter, getter
        );

    }
    % endfor
}
</%def>

${c_notice()}

/*
 * This code is C++14
 */
#ifndef INCLUA_GDNATIVE_HPP
#define INCLUA_GDNATIVE_HPP

#include <cstring>
#include <type_traits>

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
// Helpers
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
template<typename T>
INCLUA_DECL godot_variant to_variant(const T& val) {
    godot_variant var;
    if (std::is_same<T, bool>::value) {
        api->godot_variant_new_bool(&var, val);
    }
    else if (std::is_pointer<T>::value) {
        // TODO: pointers
    }
    else if (std::is_integral<T>::value) {
        if (std::is_unsigned<T>::value) {
            api->godot_variant_new_uint(&var, val);
        }
        else {
            api->godot_variant_new_uint(&var, val);
        }
    }
    else if (std::is_floating_point<T>::value) {
        api->godot_variant_new_real(&var, val);
    }
    return var;
}

INCLUA_DECL godot_variant string_to_variant(const char *s) {
    godot_variant var;
    StringHelper gs = s;
    api->godot_variant_new_string(&var, gs);
    return var;
}

///////////////////////////////////////////////////////////////////////////////
// Variant -> Data
///////////////////////////////////////////////////////////////////////////////
template<typename T>
INCLUA_DECL T from_variant(const godot_variant *var) {
    if (std::is_same<T, bool>::value) {
        return api->godot_variant_as_bool(var);
    }
    else if (std::is_pointer<T>::value) {
        // TODO: poniters
    }
    else if (std::is_integral<T>::value) {
        if (std::is_unsigned<T>::value) {
            return api->godot_variant_as_uint(var);
        }
        else {
            return api->godot_variant_as_int(var);
        }
    }
    else if (std::is_floating_point<T>::value) {
        return api->godot_variant_as_real(var);
    }
    else {
        godot_object *go = api->godot_variant_as_object(var);
        void *data = nativescript_api->godot_nativescript_get_userdata(go);
        return *((T *) data);
    }
}

///////////////////////////////////////////////////////////////////////////////
// Classes
///////////////////////////////////////////////////////////////////////////////
% for d in definitions:
    % if d.kind in ('struct', 'union'):
${def_record(d)}
    % elif d.kind == 'function':
${def_function(d)}
    % endif
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
% for d in definitions:
    % if d.kind in ('struct', 'union'):
    inclua::${REGISTER_NAME.format(d.name)}(p_handle);
    % endif
% endfor
}

} // extern "C"
#endif

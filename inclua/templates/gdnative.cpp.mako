<%namespace file="inclua.notice.mako" import="c_notice"/>

<%!
    import re
    from textwrap import dedent

    from c_api_extract import typed_declaration

    REGISTER_NAME = '{}_register'
    NEW_NAME = '{}_new'
    CONSTRUCTOR_NAME = '{}_constructor'
    DESTRUCTOR_NAME = '{}_destructor'
    SETTER_NAME = '{0}_set_{1}'
    GETTER_NAME = '{0}_get_{1}'
    WRAPPER_NAME = 'wrap_{}'
    C_ESCAPE_RE = re.compile(r'[^a-zA-Z_]')

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

    def c_escape(s):
        return C_ESCAPE_RE.sub('_', s)
%>

<%def name="to_variant_for(t)" filter="trim">
<% t = t.root() %>
% if t.is_string():
    string_variant
% elif t.kind == 'void':
    nil_variant
% elif t.kind == 'uint':
    uint_variant
% elif t.kind == 'int':
    int_variant
% elif t.kind == 'float':
    float_variant
% elif t.is_record() or (t.kind == 'pointer' and t.element_type.root().is_record()):
    object_variant
% else:
    <% assert False, "Invalid to_variant for {!r}".format(t.spelling) %>
% endif
</%def>

<%def name="set_from_variant(t, rhs, var)" filter="trim">
<% t = t.root() %>
% if t.kind == 'bool':
    ${rhs} = api->godot_variant_as_bool(${var});
% elif t.kind == 'uint':
    ${rhs} = api->godot_variant_as_uint(${var});
% elif t.kind == 'int':
    ${rhs} = api->godot_variant_as_int(${var});
% elif t.kind == 'float':
    ${rhs} = api->godot_variant_as_real(${var});
% elif t.is_record():
    ${rhs} = object_from_variant<${t.spelling}>(${var});
% elif t.kind == 'pointer' and t.element_type.root().is_record():
    ${rhs} = object_pointer_from_variant<${t.spelling}>(${var});
% elif t.is_string():
    StringHelper ${rhs | c_escape}_string_helper = ${var};
    ${rhs} = ${rhs | c_escape}_string_helper.str();
% else:
    <% assert False, "Invalid from_variant for {!r}".format(t.spelling) %>
% endif
</%def>

<%def name="record_forward_decl(d)" filter="trim">
godot_class_constructor ${NEW_NAME.format(d.name)}; 
INCLUA_DECL godot_variant object_variant(const ${d.spelling}& o);
</%def>

<%def name="def_record(d)" filter="trim">
    <%def name="def_getter(f)" filter="dedent,trim">
    INCLUA_DECL GDCALLINGCONV godot_variant ${GETTER_NAME.format(d.name, f.name)}(godot_object *go, void *method_data, void *data) {
        ${d.spelling} *obj = (${d.spelling} *) data;
        return ${to_variant_for(f.type)}(obj->${f.name});
    }
    </%def>
    <%def name="def_setter(f)" filter="dedent,trim">
    INCLUA_DECL GDCALLINGCONV void ${SETTER_NAME.format(d.name, f.name)}(godot_object *go, void *method_data, void *data, godot_variant *var) {
        ${d.spelling} *obj = (${d.spelling} *) data;
    % if f.type.is_string():
        if (obj->${f.name}) {
            free((void *) obj->${f.name});
        }
        StringHelper gs = var;
        obj->${f.name} = strndup(gs.str(), gs.size());
    % else:
        ${set_from_variant(f.type, "obj->{}".format(f.name), "var")}
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
    ${NEW_NAME.format(d.name)} = api->godot_get_class_constructor("${class_name}");
% for f in d.fields:
    {
        godot_property_attributes attr = {
            GODOT_METHOD_RPC_MODE_DISABLED, ${godot_variant_type(f.type)},
            GODOT_PROPERTY_HINT_NONE, godot_string(), GODOT_PROPERTY_USAGE_DEFAULT,
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
INCLUA_DECL godot_variant object_variant(const ${d.spelling}& o) {
    godot_variant var;
    godot_object *go = ${NEW_NAME.format(d.name)}();
    // *((${d.spelling} *) nativescript_api->godot_nativescript_get_userdata(go)) = o;
    api->godot_variant_new_object(&var, go);
    api->godot_object_destroy(go);
    return var;
}
</%def>

<%def name="def_function(d)" filter="trim">
INCLUA_DECL GDCALLINGCONV godot_variant ${WRAPPER_NAME.format(d.name)}(godot_object *go, void *method_data, void *data, int argc, godot_variant **argv) {
% for a in d.arguments:
    ${set_from_variant(a.type, typed_declaration(a.type.spelling, a.name), "argv[{}]".format(loop.index))}
% endfor
% if d.return_type.kind == 'void':
    ${d.name}(${', '.join(a.name for a in d.arguments)});
    return nil_variant();
% else:
    auto result = ${d.name}(${', '.join(a.name for a in d.arguments)});
    return ${to_variant_for(d.return_type)}(result);
% endif
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
INCLUA_DECL godot_variant nil_variant() {
    godot_variant var;
    api->godot_variant_new_nil(&var);
    return var;
}
template<typename T> INCLUA_DECL godot_variant bool_variant(T b) {
    godot_variant var;
    api->godot_variant_new_bool(&var, b);
    return var;
}
template<typename T> INCLUA_DECL godot_variant uint_variant(T u) {
    godot_variant var;
    api->godot_variant_new_uint(&var, u);
    return var;
}
template<typename T> INCLUA_DECL godot_variant int_variant(T i) {
    godot_variant var;
    api->godot_variant_new_int(&var, i);
    return var;
}
template<typename T> INCLUA_DECL godot_variant float_variant(T f) {
    godot_variant var;
    api->godot_variant_new_real(&var, f);
    return var;
}
INCLUA_DECL godot_variant string_variant(const char *s) {
    godot_variant var;
    StringHelper gs = s;
    api->godot_variant_new_string(&var, gs);
    return var;
}

///////////////////////////////////////////////////////////////////////////////
// Variant -> Data
///////////////////////////////////////////////////////////////////////////////
template<typename T> INCLUA_DECL T object_from_variant(const godot_variant *var) {
    godot_object *go = api->godot_variant_as_object(var);
    void *data = nativescript_api->godot_nativescript_get_userdata(go);
    return *((T *) data);
}
template<typename T> INCLUA_DECL T object_pointer_from_variant(const godot_variant *var) {
    godot_object *go = api->godot_variant_as_object(var);
    void *data = nativescript_api->godot_nativescript_get_userdata(go);
    return (T) data;
}

///////////////////////////////////////////////////////////////////////////////
// Forward declarations
///////////////////////////////////////////////////////////////////////////////
% for d in definitions:
    % if d.is_record():
${record_forward_decl(d)}
    % endif
% endfor
///////////////////////////////////////////////////////////////////////////////
// Functions
///////////////////////////////////////////////////////////////////////////////
% for d in definitions:
    % if d.kind == 'function':
${def_function(d)}
    % endif
% endfor
///////////////////////////////////////////////////////////////////////////////
// Classes
///////////////////////////////////////////////////////////////////////////////
% for d in definitions:
    % if d.is_record():
${def_record(d)}
    % endif
% endfor

///////////////////////////////////////////////////////////////////////////////
// Global scope: enums, all functions, constants, variables
///////////////////////////////////////////////////////////////////////////////
INCLUA_DECL GDCALLINGCONV void *_global_constructor(godot_object *go, void *method_data) { return NULL; }
INCLUA_DECL GDCALLINGCONV void _global_destructor(godot_object *go, void *method_data, void *data) {}
void _global_register(void *p_handle) {
    godot_instance_create_func create_func = { &_global_constructor, NULL, NULL };
    godot_instance_destroy_func destroy_func = { &_global_destructor, NULL, NULL };
    nativescript_api->godot_nativescript_register_class(
        p_handle, "Global", "Reference",
        create_func, destroy_func
    );
    godot_method_attributes method_attr = {};
% for d in definitions:
    % if d.kind == 'function':
    {
        godot_instance_method method = { &${WRAPPER_NAME.format(d.name)}, NULL, NULL };
        nativescript_api->godot_nativescript_register_method(
            p_handle, "Global", "${d.name}", method_attr, method
        );
    }
    % endif
% endfor

}

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
    inclua::_global_register(p_handle);
% for d in definitions:
    % if d.is_record():
    inclua::${REGISTER_NAME.format(d.name)}(p_handle);
    % endif
% endfor
}

} // extern "C"
#endif

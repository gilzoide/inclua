<%namespace file="inclua.notice.mako" import="c_notice"/>

<%
    import re
    from textwrap import dedent

    from c_api_extract import typed_declaration

    C_ESCAPE_RE = re.compile(r'[^a-zA-Z_]')

    def class_name_for(type):
        return oop.get_unprefixed_name(type)

    def c_escape(s):
        return C_ESCAPE_RE.sub('_', s)

    def opt_argument(s):
        return ', ' + s if s else ''

    classes = list(oop.iter_types())
    nativescripts = ['Global']
    nativescripts.extend(c.name for c in classes)
%>

<%def name="REGISTER_NAME(n)" filter="trim">
    ${n}_register
</%def>
<%def name="CONSTRUCTOR_NAME(n)" filter="trim">
    ${n}_constructor
</%def>
<%def name="DESTRUCTOR_NAME(n)" filter="trim">
    ${n}_destructor
</%def>
<%def name="SETTER_NAME(t, p)" filter="trim">
    ${t}_set_${p}
</%def>
<%def name="GETTER_NAME(t, p)" filter="trim">
    ${t}_get_${p}
</%def>
<%def name="WRAPPER_NAME(n)" filter="trim">
    _global_${n}
</%def>
<%def name="METHOD_NAME(t, n)" filter="trim">
    ${t}_${n}
</%def>
<%def name="NATIVESCRIPT_NAME(n)" filter="trim">
    ${n}_nativescript
</%def>

<%def name="godot_variant_type(t)" filter="trim">
    % if t.kind == 'bool':
        GODOT_VARIANT_TYPE_BOOL
    % elif t.is_integral():
        GODOT_VARIANT_TYPE_INT
    % elif t.is_floating_point():
        GODOT_VARIANT_TYPE_REAL
    % elif t.is_string():
        GODOT_VARIANT_TYPE_STRING
    % else:
        GODOT_VARIANT_TYPE_OBJECT
    %endif
</%def>


<%def name="to_variant_for(t, val, size='')" filter="trim">
<% t = t.root() %>
% if t.is_string():
    string_variant(${val}${', ' + size if size else ''})
% elif t.kind == 'void':
    nil_variant(${val})
% elif t.kind in ('uint', 'enum'):
    uint_variant(${val})
% elif t.kind == 'int':
    int_variant(${val})
% elif t.kind == 'float':
    float_variant(${val})
% elif t.is_record():
    object_variant(${val}, ${NATIVESCRIPT_NAME(t.name)})
% elif t.kind == 'pointer' and t.element_type.root().is_record():
    object_variant(${val}, ${NATIVESCRIPT_NAME(t.element_type)})
% else:
    <% assert False, "Invalid to_variant for {!r}".format(t.spelling) %>
% endif
</%def>

<%def name="arg_from_variant(t, rhs, var, size='')" filter="trim">
<% t = t.root() %>
% if t.kind == 'bool':
    ${rhs} = api->godot_variant_as_bool(${var});
% elif t.kind == 'char':
    ${rhs} = char_from_variant(${var});
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
    StringHelper ${rhs | c_escape}_helper = ${var};
    ${rhs} = ${rhs | c_escape}_helper.str();
    % if size:
    ${size} = ${rhs | c_escape}_helper.length();
    % endif
% elif t.kind in ('pointer', 'array'):
<% element_type = t.element_type.root() %>
    % if element_type.kind in ('int', 'uint'):
    IntArrayHelper<${element_type.spelling}> ${rhs | c_escape}_helper = ${var};
    % elif element_type.kind == 'float':
    FloatArrayHelper<${element_type.spelling}> ${rhs | c_escape}_helper = ${var};
    % else:
    % endif
    ${rhs} = ${rhs | c_escape}_helper.buffer;
    % if size:
    ${size} = ${rhs | c_escape}_helper.size;
    % endif
% else:
    <% assert False, "Invalid from_variant for {!r}".format(t.spelling) %>
% endif
</%def>

<%def name="set_from_variant(t, rhs, var, size='')" filter="trim">
<% t = t.root() %>
% if t.is_string():
    set_string_from_variant(${rhs}${opt_argument(size)}, ${var});
% else:
    ${arg_from_variant(t, rhs, var, size)}
% endif
</%def>

<%def name="def_record(d)" filter="trim">
    <%def name="def_getter(f)" filter="dedent,trim">
        <%
            size = annotations.get_array_size(d.name, f.name).strip()
            if size and size in (f.name for f in d.fields):
                size = 'obj->' + size
        %>
        INCLUA_DECL GDCALLINGCONV godot_variant ${GETTER_NAME(d.name, f.name)}(godot_object *go, void *method_data, void *data) {
            ${d.spelling} *obj = (${d.spelling} *) data;
            return ${to_variant_for(f.type, "obj->" + f.name, size)};
        }
    </%def>
    <%def name="def_setter(f)" filter="dedent,trim">
        <%
            size = annotations.get_array_size(d.name, f.name).strip()
            obj_size = 'obj->' + size if (size and size in (f.name for f in d.fields)) else ''
            obj_field = 'obj->' + f.name
        %>
        INCLUA_DECL GDCALLINGCONV void ${SETTER_NAME(d.name, f.name)}(godot_object *go, void *method_data, void *data, godot_variant *var) {
            ${d.spelling} *obj = (${d.spelling} *) data;
            ${set_from_variant(f.type, obj_field, "var", size=obj_size)}
        }
    </%def>
    <%def name="def_method(f)" filter="dedent,trim">
        DEFINE_METHOD_WRAPPING_FUNC(${METHOD_NAME(d.name, f.name)}, ${WRAPPER_NAME(f.name)})
    </%def>
<%
    class_name = class_name_for(d)
%>
INCLUA_DECL GDCALLINGCONV void *${CONSTRUCTOR_NAME(d.name)}(godot_object *go, void *method_data) {
    ${d.spelling} *obj = (${d.spelling} *) api->godot_alloc(sizeof(${d.spelling}));
    *obj = {};
    return obj;
}
INCLUA_DECL GDCALLINGCONV void ${DESTRUCTOR_NAME(d.name)}(godot_object *go, void *method_data, void *data) {
    ${d.spelling} *obj = (${d.spelling} *) data;
% if oop.destructor.get(d.name):
    ${oop.destructor[d.name].name}(obj);
% endif
% for f in d.fields:
    % if f.type.is_string():
    if (obj->${f.name}) api->godot_free((void *) obj->${f.name});
    % endif
% endfor
    api->godot_free(obj);
}

% for f in d.fields:
${def_setter(f)}
${def_getter(f)}
% endfor

% for method in oop.get_methods(d):
${def_method(method)}
% endfor

INCLUA_DECL void ${REGISTER_NAME(d.name)}(void *p_handle) {
    godot_instance_create_func create_func = { &${CONSTRUCTOR_NAME(d.name)}, NULL, NULL };
    godot_instance_destroy_func destroy_func = { &${DESTRUCTOR_NAME(d.name)}, NULL, NULL };
    nativescript_api->godot_nativescript_register_class(
        p_handle, "${class_name}", "Reference",
        create_func, destroy_func
    );
% for f in d.fields:
    {
        godot_property_attributes attr = {
            GODOT_METHOD_RPC_MODE_DISABLED, ${godot_variant_type(f.type)},
            GODOT_PROPERTY_HINT_NONE, godot_string(), GODOT_PROPERTY_USAGE_DEFAULT,
        };
        godot_property_get_func getter = { &${GETTER_NAME(d.name, f.name)}, NULL, NULL };
        godot_property_set_func setter = { &${SETTER_NAME(d.name, f.name)}, NULL, NULL };
        nativescript_api->godot_nativescript_register_property(
            p_handle, "${class_name}", "${f.name}",
            &attr, setter, getter
        );
    }
% endfor
    godot_method_attributes method_attr = {};
% for method in oop.get_methods(d):
    {
        godot_instance_method method = { &${METHOD_NAME(d.name, method.name)}, NULL, NULL };
        nativescript_api->godot_nativescript_register_method(
            p_handle, "${class_name}", "${method.name}", method_attr, method
        );
    }
% endfor
    ${NATIVESCRIPT_NAME(d.name)} = NATIVESCRIPT_FOR_CLASS_LITERAL("${class_name}");
}
</%def>

<%def name="def_function(d)" filter="trim">
<% i = -1 %>
INCLUA_DECL GDCALLINGCONV godot_variant ${WRAPPER_NAME(d.name)}(godot_object *go, void *method_data, void *data, int argc, godot_variant **argv) {
% for a in d.arguments:
<%
    if annotations.is_argument_size(d.name, a.name):
        continue
    i += 1
    size = annotations.get_array_size(d.name, a.name)
    param_size = 'size_t ' + size if (size and size in (a.name for a in d.arguments)) else ''
%>\
    ${arg_from_variant(a.type, typed_declaration(a.type.spelling, a.name), "argv[{}]".format(i), size=param_size)}
% endfor
% if d.return_type.kind == 'void':
    ${d.name}(${', '.join(a.name for a in d.arguments)});
    return nil_variant();
% else:
    ${d.return_type.spelling} result = ${d.name}(${', '.join(a.name for a in d.arguments)});
    return ${to_variant_for(d.return_type, "result")};
% endif
}
</%def>

<%def name="def_global_getter(d)" filter="trim">
INCLUA_DECL GDCALLINGCONV godot_variant ${GETTER_NAME("Global", d.name)}(godot_object *go, void *method_data, void *data) {
    return ${to_variant_for(d.type, d.name)};
}
</%def>

<%def name="def_global_setter(d)" filter="trim">
INCLUA_DECL GDCALLINGCONV void ${SETTER_NAME("Global", d.name)}(godot_object *go, void *method_data, void *data, godot_variant *var) {
% if f.type.is_string():
    <% assert False, "Setting global strings is not support yet" %>
% else:
    ${set_from_variant(d.type, d.name, "var")}
% endif
}
</%def>

${c_notice()}

/*
 * This code is C++11
 */
#ifndef INCLUA_GDNATIVE_HPP
#define INCLUA_GDNATIVE_HPP

#include <cstdint>
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

#define LOG_ERROR(msg) api->godot_print_error(msg, __PRETTY_FUNCTION__, __FILE__, __LINE__)
#define LOG_ERROR_IF_FALSE(cond) if(!(cond)) LOG_ERROR("Error: !(" #cond ")")

const godot_gdnative_core_api_struct *api = nullptr;
const godot_gdnative_ext_nativescript_api_struct *nativescript_api = nullptr;
godot_object *gd_native_library = nullptr;

godot_class_constructor Reference_new = nullptr;
godot_class_constructor NativeScript_new = nullptr;
godot_method_bind *Object_set_script = nullptr;
godot_method_bind *Object_set_meta = nullptr;
godot_method_bind *NativeScript_set_class_name = nullptr;
godot_method_bind *NativeScript_set_library = nullptr;

% for name in nativescripts:
godot_object *${NATIVESCRIPT_NAME(name)} = nullptr;
% endfor

godot_object *Global;

namespace inclua {

///////////////////////////////////////////////////////////////////////////////
// Helpers
///////////////////////////////////////////////////////////////////////////////
struct VariantHelper {
    VariantHelper() {
        api->godot_variant_new_nil(&var);
    }
    VariantHelper(godot_variant var) : var(var) {}
    ~VariantHelper() {
        api->godot_variant_destroy(&var);
    }
    operator const godot_variant() const {
        return var;
    }
    operator const godot_variant *() const {
        return &var;
    }
    // fields
    godot_variant var;
};

struct StringHelper {
    StringHelper(const char *s) : gcs_valid(false) {
        gs = api->godot_string_chars_to_utf8(s);
    }
    StringHelper(const char *s, size_t length) : gcs_valid(false) {
        gs = api->godot_string_chars_to_utf8_with_len(s, length);
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
    char *strdup() {
        godot_int len = length();
        const char *s = str();
        char *buffer = (char *) api->godot_alloc(len + 1);
        if (buffer) {
            memcpy(buffer, s, len);
            buffer[len] = 0;
        }
        return buffer;
    }
    godot_int length() const {
        return api->godot_string_length(&gs);
    }
    godot_variant var() const {
        godot_variant newvar;
        api->godot_variant_new_string(&newvar, &gs);
        return newvar;
    }
    operator godot_string *() {
        return &gs;
    }
    // fields
    godot_string gs;
    godot_char_string gcs;
    bool gcs_valid;
};

template<typename T> T *buffer_from_pool_byte_array(godot_pool_byte_array byte_array, size_t *out_size) {
    size_t size = api->godot_pool_byte_array_size(&byte_array) / sizeof(T);
    if (T *buffer = (T *) api->godot_alloc(size * sizeof(T))) {
        godot_pool_byte_array_read_access *read = api->godot_pool_byte_array_read(&byte_array);
        memcpy(buffer, api->godot_pool_byte_array_read_access_ptr(read), size * sizeof(T));
        api->godot_pool_byte_array_read_access_destroy(read);
        *out_size = size;
        return buffer;
    }
    else {
        *out_size = 0;
        return nullptr;
    }
}

template<typename T> T *buffer_from_pool_int_array(godot_pool_int_array int_array, size_t *out_size) {
    size_t size = api->godot_pool_int_array_size(&int_array);
    if (T *buffer = (T *) api->godot_alloc(size * sizeof(T))) {
        godot_pool_int_array_read_access *read = api->godot_pool_int_array_read(&int_array);
        const godot_int *int_ptr = api->godot_pool_int_array_read_access_ptr(read);
        if (std::is_same<T, godot_int>::value) {
            memcpy(buffer, int_ptr, size * sizeof(T));
        }
        else {
            for (size_t i = 0; i < size; i++) {
                buffer[i] = (T) int_ptr[i];
            }
        }
        api->godot_pool_int_array_read_access_destroy(read);
        *out_size = size;
        return buffer;
    }
    else {
        *out_size = 0;
        return nullptr;
    }
}

template<typename T> T *buffer_from_pool_real_array(godot_pool_real_array real_array, size_t *out_size) {
    size_t size = api->godot_pool_real_array_size(&real_array);
    if (T *buffer = (T *) api->godot_alloc(size * sizeof(T))) {
        godot_pool_real_array_read_access *read = api->godot_pool_real_array_read(&real_array);
        const godot_real *real_ptr = api->godot_pool_real_array_read_access_ptr(read);
        if (std::is_same<T, godot_real>::value) {
            memcpy(buffer, real_ptr, size * sizeof(T));
        }
        else {
            for (size_t i = 0; i < size; i++) {
                buffer[i] = (T) real_ptr[i];
            }
        }
        api->godot_pool_real_array_read_access_destroy(read);
        *out_size = size;
        return buffer;
    }
    else {
        *out_size = 0;
        return nullptr;
    }
}

template<typename T> struct IntArrayHelper {
    IntArrayHelper(const godot_variant *var) {
        switch (api->godot_variant_get_type(var)) {
            case GODOT_VARIANT_TYPE_POOL_BYTE_ARRAY: {
                godot_pool_byte_array arr = api->godot_variant_as_pool_byte_array(var);
                buffer = buffer_from_pool_byte_array<T>(arr, &size);
                api->godot_pool_byte_array_destroy(&arr);
                break;
            }
            default:
                godot_pool_int_array arr = api->godot_variant_as_pool_int_array(var);
                buffer = buffer_from_pool_int_array<T>(arr, &size);
                api->godot_pool_int_array_destroy(&arr);
                break;
        }
    }
    ~IntArrayHelper() {
        if (buffer) api->godot_free(buffer);
    }
    // fields
    T *buffer;
    size_t size;
};

template<typename T> struct FloatArrayHelper {
    FloatArrayHelper(const godot_variant *var) {
        switch (api->godot_variant_get_type(var)) {
            case GODOT_VARIANT_TYPE_POOL_BYTE_ARRAY: {
                godot_pool_byte_array arr = api->godot_variant_as_pool_byte_array(var);
                buffer = buffer_from_pool_byte_array<T>(arr, &size);
                api->godot_pool_byte_array_destroy(&arr);
                break;
            }
            default:
                godot_pool_real_array arr = api->godot_variant_as_pool_real_array(var);
                buffer = buffer_from_pool_real_array<T>(arr, &size);
                api->godot_pool_real_array_destroy(&arr);
                break;
        }
    }
    ~FloatArrayHelper() {
        if (buffer) api->godot_free(buffer);
    }
    // fields
    T *buffer;
    size_t size;
};

INCLUA_DECL void set_meta(godot_object *go, const char *rawkey, const godot_variant *var) {
    StringHelper key = rawkey;
    const void *args[] = { &key.gs, var };
    api->godot_method_bind_ptrcall(Object_set_meta, go, args, nullptr);
}

INCLUA_DECL godot_object *nativescript_for_class(const char *classname, size_t length) {
    StringHelper classname_gs = { classname, length };
    const void *classname_arg[] = { &classname_gs.gs };
    godot_object *script = NativeScript_new();
    api->godot_method_bind_ptrcall(NativeScript_set_library, script, (const void **) &gd_native_library, nullptr);
    api->godot_method_bind_ptrcall(NativeScript_set_class_name, script, classname_arg, nullptr);
    return script;
}
<%text filter="trim">
#define NATIVESCRIPT_FOR_CLASS_LITERAL(classname) \
    nativescript_for_class(classname, sizeof(classname))

#define DEFINE_METHOD_WRAPPING_FUNC(method_name, func_name)                   \
    INCLUA_DECL GDCALLINGCONV godot_variant method_name(godot_object *go, void *method_data, void *data, int argc, godot_variant **argv) { \
        godot_variant *wrapper_argv[argc + 1];                                \
        godot_variant self;                                                   \
        api->godot_variant_new_object(&self, go);                             \
        wrapper_argv[0] = &self;                                              \
        for (int i = 0; i < argc; i++) {                                      \
            wrapper_argv[i + 1] = argv[i];                                    \
        }                                                                     \
        return func_name(Global, nullptr, nullptr, argc + 1, wrapper_argv);   \
    }
</%text>

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
    StringHelper gs = s;
    return gs.var();
}
INCLUA_DECL godot_variant string_variant(const char *s, size_t lenght) {
    StringHelper gs = { s, lenght };
    return gs.var();
}
INCLUA_DECL godot_variant dictionary_variant(const godot_dictionary *dict) {
    godot_variant var;
    api->godot_variant_new_dictionary(&var, dict);
    return var;
}

INCLUA_DECL godot_object *new_object_with_script(const godot_object *script) {
    godot_object *go = Reference_new();
    api->godot_method_bind_ptrcall(Object_set_script, go, (const void **) &script, nullptr);
    return go;
}
template<typename T> INCLUA_DECL godot_variant object_variant(const T& value, const godot_object *script) {
    godot_object *go = new_object_with_script(script);
    *((T *) nativescript_api->godot_nativescript_get_userdata(go)) = value;
    godot_variant var;
    api->godot_variant_new_object(&var, go);
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

INCLUA_DECL char char_from_variant(const godot_variant *var) {
    switch (api->godot_variant_get_type(var)) {
        case GODOT_VARIANT_TYPE_NIL: return 0;
        case GODOT_VARIANT_TYPE_INT: return (char) api->godot_variant_as_int(var);
        case GODOT_VARIANT_TYPE_STRING: {
            StringHelper gs = var;
            return gs.length() ? gs.str()[0] : 0;
        }
        default:
            LOG_ERROR("Invalid type, should be int, string or null");
            return 0;
    }
}

template<typename T> INCLUA_DECL void set_string_from_variant(T& cstr, const godot_variant *var) {
    if (cstr) api->godot_free((void *) cstr);
    StringHelper gs = var;
    cstr = gs.strdup();
}
template<typename T, typename S> INCLUA_DECL void set_string_from_variant(T& cstr, S& length, const godot_variant *var) {
    if (cstr) api->godot_free((void *) cstr);
    StringHelper gs = var;
    cstr = gs.strdup();
    length = gs.length();
}

///////////////////////////////////////////////////////////////////////////////
// Bound values getters
///////////////////////////////////////////////////////////////////////////////
INCLUA_DECL godot_variant get_bound_uint(godot_object *go, void *method_data, void *data) {
    uintptr_t u = (uintptr_t) method_data;
    return uint_variant(u);
}
INCLUA_DECL godot_variant get_bound_dictionary(godot_object *go, void *method_data, void *data) {
    const godot_dictionary *dict = (const godot_dictionary *) method_data;
    return dictionary_variant(dict);
}

///////////////////////////////////////////////////////////////////////////////
// Constants and variables
///////////////////////////////////////////////////////////////////////////////
% for d in definitions:
    % if d.kind == 'const':
${def_global_getter(d)}
    % elif d.kind == 'var':
${def_global_getter(d)}
${def_global_setter(d)}
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
INCLUA_DECL GDCALLINGCONV void *_global_constructor(godot_object *go, void *method_data) { return nullptr; }
INCLUA_DECL GDCALLINGCONV void _global_destructor(godot_object *go, void *method_data, void *data) {}
void _global_register(void *p_handle) {
    godot_instance_create_func create_func = { &_global_constructor, NULL, NULL };
    godot_instance_destroy_func destroy_func = { &_global_destructor, NULL, NULL };
    nativescript_api->godot_nativescript_register_class(
        p_handle, "Global", "Reference",
        create_func, destroy_func
    );
    ${NATIVESCRIPT_NAME("Global")} = NATIVESCRIPT_FOR_CLASS_LITERAL("Global");
    Global = new_object_with_script(${NATIVESCRIPT_NAME("Global")});  // Yay, a global Global =D
    godot_method_attributes method_attr = {};
% for d in definitions:
    % if d.kind == 'function':
    {  // ${d.name}
        godot_instance_method method = { &${WRAPPER_NAME(d.name)}, NULL, NULL };
        nativescript_api->godot_nativescript_register_method(
            p_handle, "Global", "${d.name}", method_attr, method
        );
    }
    % elif d.kind in ('var', 'const'):
    {  // ${d.name}
        godot_property_attributes attr = {
            GODOT_METHOD_RPC_MODE_DISABLED, ${godot_variant_type(d.type)},
            GODOT_PROPERTY_HINT_NONE, godot_string(), GODOT_PROPERTY_USAGE_DEFAULT,
        };
        godot_property_get_func getter = { &${GETTER_NAME("Global", d.name)}, NULL, NULL };
        godot_property_set_func setter = { ${'&' + SETTER_NAME("Global", d.name) if d.kind == 'var' else 'NULL'}, NULL, NULL };
        nativescript_api->godot_nativescript_register_property(
            p_handle, "Global", "${d.name}",
            &attr, setter, getter
        );
    }
    % elif d.kind == 'enum':
    {  // ${d.spelling}
        godot_property_attributes attr = {
            GODOT_METHOD_RPC_MODE_DISABLED, GODOT_VARIANT_TYPE_INT,
            GODOT_PROPERTY_HINT_NONE, godot_string(), GODOT_PROPERTY_USAGE_DEFAULT,
        };
        godot_property_get_func getter = { &get_bound_uint, NULL, NULL };
        godot_property_set_func setter = { NULL, NULL, NULL };
        % if not d.is_anonymous():
        static godot_dictionary enum_dict;
        api->godot_dictionary_new(&enum_dict);
        {
            godot_property_get_func getter = { &get_bound_dictionary, &enum_dict, (void (*)(void *)) api->godot_dictionary_destroy };
            nativescript_api->godot_nativescript_register_property(
                p_handle, "Global", "${d.name}",
                &attr, setter, getter
            );
        }
        % endif
        % for v in d.values:
        {
            % if not d.is_anonymous():
            VariantHelper key = string_variant("${v.name | canonicalize}");
            VariantHelper value = uint_variant(${v.name});
            api->godot_dictionary_set(&enum_dict, key, value);
            % endif
            getter.method_data = (void *) ${v.name};
            nativescript_api->godot_nativescript_register_property(
                p_handle, "Global", "${v.name}",
                &attr, setter, getter
            );
        }
        % endfor
    }
    % endif
% endfor
}

} // namespace inclua

extern "C" {

///////////////////////////////////////////////////////////////////////////////
// API initialization
///////////////////////////////////////////////////////////////////////////////
GDN_EXPORT void godot_gdnative_init(godot_gdnative_init_options *options) {
    api = options->api_struct;
    gd_native_library = options->gd_native_library;
    // Now find our extensions.
    for(int i = 0; i < api->num_extensions; i++) {
        switch(api->extensions[i]->type) {
            case GDNATIVE_EXT_NATIVESCRIPT: {
                nativescript_api = (godot_gdnative_ext_nativescript_api_struct *) api->extensions[i];
            }; break;
            default: break;
        }
    }
    // cache some references
    LOG_ERROR_IF_FALSE(Reference_new = api->godot_get_class_constructor("Reference"));
    LOG_ERROR_IF_FALSE(NativeScript_new = api->godot_get_class_constructor("NativeScript"));
    LOG_ERROR_IF_FALSE(Object_set_script = api->godot_method_bind_get_method("Object", "set_script"));
    LOG_ERROR_IF_FALSE(Object_set_meta = api->godot_method_bind_get_method("Object", "set_meta"));
    LOG_ERROR_IF_FALSE(NativeScript_set_class_name = api->godot_method_bind_get_method("NativeScript", "set_class_name"));
    LOG_ERROR_IF_FALSE(NativeScript_set_library = api->godot_method_bind_get_method("NativeScript", "set_library"));
}

GDN_EXPORT void godot_gdnative_terminate(godot_gdnative_terminate_options *options) {
    NativeScript_set_library = nullptr;
    NativeScript_set_class_name = nullptr;
    Object_set_script = nullptr;
    NativeScript_new = nullptr;
    nativescript_api = nullptr;
    gd_native_library = nullptr;
    api = nullptr;
}

GDN_EXPORT void godot_nativescript_init(void *p_handle) {
    inclua::_global_register(p_handle);
% for d in definitions:
    % if d.is_record():
    inclua::${REGISTER_NAME(d.name)}(p_handle);
    % endif
% endfor
}

} // extern "C"
#endif

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

<%def name="godot_variant_type(t, is_array=False)" filter="trim">
    <% t = t.root() %>
    % if t.kind == 'bool':
        GODOT_VARIANT_TYPE_BOOL
    % elif t.is_integral():
        GODOT_VARIANT_TYPE_INT
    % elif t.is_floating_point():
        GODOT_VARIANT_TYPE_REAL
    % elif t.is_string():
        GODOT_VARIANT_TYPE_STRING
    % elif t.kind in ('array', 'vector') or (t.kind == 'pointer' and is_array): 
        <% element_type = t.remove_array().root() %>
        % if element_type.is_string():
            GODOT_VARIANT_TYPE_POOL_STRING_ARRAY
        % else:
            GODOT_VARIANT_TYPE_ARRAY
        % endif
    % else:
        GODOT_VARIANT_TYPE_OBJECT
    %endif
</%def>


<%def name="to_variant_for(t, val, size='', is_array=False, free='')" filter="trim">
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
% elif t.kind in ('array', 'vector') or (t.kind == 'pointer' and (size or is_array)): 
<% element_type = t.remove_array().root() %>
    % if element_type.kind in ('int', 'uint'):
        <% assert size, "Int array must have a known size" %>
    int_array_variant(${val}, ${size})
    % elif element_type.kind == 'float':
        <% assert size, "Float array must have a known size" %>
    float_array_variant(${val}, ${size})
    % elif element_type.is_string():
        <% assert size, "String array must have a known size" %>
    string_array_variant(${val}, ${size})
    % elif element_type.is_record():
        <% assert size, "Object array must have a known size" %>
    object_array_variant(${val}, ${size}, ${NATIVESCRIPT_NAME(element_type.name)})
    % else:
        <% assert False, "Array of {!r} is not supported yet" %>
    % endif
% elif t.kind == 'pointer' and t.remove_array().root().is_record():
    object_variant(${val}, ${NATIVESCRIPT_NAME(t.element_type.name)})
% else:
    <% assert False, "Invalid to_variant for {!r}".format(t.to_dict()) %>
% endif
</%def>

<%def name="arg_from_variant(t, rhs, var, size='', is_array=False)" filter="trim">
<% t = t.root() %>
% if t.kind == 'bool':
    ${rhs} = (${t.spelling}) api->godot_variant_as_bool(${var});
% elif t.kind == 'char':
    ${rhs} = (${t.spelling}) char_from_variant(${var});
% elif t.kind in ('uint', 'enum'):
    ${rhs} = (${t.spelling}) api->godot_variant_as_uint(${var});
% elif t.kind == 'int':
    ${rhs} = (${t.spelling}) api->godot_variant_as_int(${var});
% elif t.kind == 'float':
    ${rhs} = (${t.spelling}) api->godot_variant_as_real(${var});
% elif t.is_record():
    ${rhs} = object_from_variant<${t.spelling}>(${var});
% elif t.is_string():
    StringHelper ${rhs | c_escape}_helper = ${var};
    ${rhs} = ${rhs | c_escape}_helper.str();
    % if size:
    ${size} = ${rhs | c_escape}_helper.length();
    % endif
% elif t.kind in ('array', 'vector') or (t.kind == 'pointer' and (size or is_array)):
<% 
    element_type = t.remove_array().root()
    helper_name = c_escape(rhs)
%>
    % if element_type.kind in ('int', 'uint'):
    IntArrayHelper<${element_type.spelling}> ${helper_name} = ${var};
    % elif element_type.kind == 'float':
    FloatArrayHelper<${element_type.spelling}> ${helper_name} = ${var};
    % elif element_type.is_record() or element_type.remove_array().root().is_record():
    ObjectArrayHelper<${element_type.spelling}> ${helper_name} = ${var};
    % else:
        <% assert False, "from_variant not supported yet for {!r}".format(t.to_dict()) %>
    % endif
    ${rhs} = ${helper_name}.buffer;
    % if size:
    ${size} = ${helper_name}.size;
    % endif
% elif t.kind == 'pointer' and t.element_type.root().is_record():
    ${rhs} = object_pointer_from_variant<${t.spelling}>(${var});
% else:
    <% assert False, "Invalid from_variant for {!r}".format(t.spelling) %>
% endif
</%def>

<%def name="set_from_variant(t, rhs, var, size='', is_array=False)" filter="trim">
<% t = t.root() %>
% if t.is_string():
    set_string_from_variant(${rhs}${opt_argument(size)}, ${var});
% elif t.kind in ('array', 'vector') or (t.kind == 'pointer' and (size or is_array)):
<% element_type = t.remove_array().root() %>
    % if element_type.kind in ('int', 'uint'):
    set_int_array_from_variant(${rhs}${opt_argument(size)}, ${var});
    % elif element_type.kind == 'float':
    set_float_array_from_variant(${rhs}${opt_argument(size)}, ${var});
    % elif element_type.is_string():
    set_string_array_from_variant(${rhs}${opt_argument(size)}, ${var});
    % else:
        <% assert False, "Only int and float arrays are supported" %>
    % endif
% else:
    ${arg_from_variant(t, rhs, var, size, is_array)}
% endif
</%def>

<%def name="def_record(d)" filter="trim">
<%
    class_name = class_name_for(d)
%>
    <%def name="def_getter(f)" filter="dedent,trim">
        <%
            size = annotations.get_array_size(d.name, f.name).strip()
            if size and size in (f.name for f in d.fields):
                size = 'obj->' + size
        %>
        INCLUA_DECL GDCALLINGCONV godot_variant ${GETTER_NAME(d.name, f.name)}(godot_object *go, void *method_data, void *data) {
            RecordHelper *helper = (RecordHelper *) data;
            ${d.spelling} *obj = (${d.spelling} *) helper->ptr;
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
            RecordHelper *helper = (RecordHelper *) data;
            ${d.spelling} *obj = (${d.spelling} *) helper->ptr;
            ${set_from_variant(f.type, obj_field, "var", size=obj_size)}
        }
    </%def>
INCLUA_DECL GDCALLINGCONV void *${CONSTRUCTOR_NAME(d.name)}(godot_object *go, void *method_data) {
    RecordHelper *helper = (RecordHelper *) api->godot_alloc(sizeof(RecordHelper));
    *helper = {};
% if not d.opaque:
    ${d.spelling} zeroinit = {};
    helper->set(&zeroinit, api->godot_free);
% endif
    return helper;
}
INCLUA_DECL GDCALLINGCONV void ${DESTRUCTOR_NAME(d.name)}(godot_object *go, void *method_data, void *data) {
    RecordHelper *helper = (RecordHelper *) data;
    if (helper->owns_data()) {
        ${d.spelling} *obj = (${d.spelling} *) helper->ptr;
<% destructor = oop.get_destructor(d) %>\
% if destructor:
        ${destructor.name}(${"" if destructor.arguments[0].type.is_pointer() else "*"}obj);
% endif
% for f in d.fields:
<% free_func = annotations.get_free_func(d.name, f.name) %>\
    % if free_func:
        ${free_func}(obj->${f.name});
    % elif f.type.is_string():
        if (obj->${f.name}) api->godot_free((void *) obj->${f.name});
    % elif f.type.is_pointer() and annotations.is_array(d.name, f.name):
        if (obj->${f.name}) {
<% 
    size = annotations.get_array_size(d.name, f.name)
    obj_size = 'obj->' + size if (size and size in (f.name for f in d.fields)) else size
    element_type = f.type.remove_array().root()
%>\
        % if element_type.is_string():
            % if size:
            size_t size = ${obj_size};
            for (size_t i = 0; i < size; i++) {
                if (obj->${f.name}[i]) api->godot_free((void *) obj->${f.name}[i]);
            }
            % else:
            for (${f.type.spelling} it = obj->${f.name}; *it; it++) api->godot_free((void *) *it);
            % endif
        % endif
            api->godot_free((void *) obj->${f.name});
        }
    % endif
% endfor
        helper->free_ptr();
    }
    api->godot_free(data);
}

% for f in d.fields:
${def_setter(f)}
${def_getter(f)}
% endfor

INCLUA_DECL void ${REGISTER_NAME(d.name)}(void *p_handle) {
    godot_instance_create_func create_func = { &${CONSTRUCTOR_NAME(d.name)}, NULL, NULL };
    godot_instance_destroy_func destroy_func = { &${DESTRUCTOR_NAME(d.name)}, NULL, NULL };
    nativescript_api->godot_nativescript_register_class(
        p_handle, "${class_name}", "Reference",
        create_func, destroy_func
    );
% for f in d.fields:
<% is_array = annotations.is_array(d.name, f.name) %>\
    {
        godot_property_attributes attr = {
            GODOT_METHOD_RPC_MODE_DISABLED, ${godot_variant_type(f.type, is_array=is_array)},
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
    godot_instance_method method = { &call_function_as_method, NULL, NULL };
% for method in oop.get_methods(d):
    {
        method.method_data = (void *) &${WRAPPER_NAME(method.name)};
        nativescript_api->godot_nativescript_register_method(
            p_handle, "${class_name}", "${method.name}", method_attr, method
        );
    }
% endfor
    ${NATIVESCRIPT_NAME(d.name)} = NATIVESCRIPT_FOR_CLASS_LITERAL("${class_name}");
    reference(${NATIVESCRIPT_NAME(d.name)});
}
</%def>

<%def name="def_function(d)" filter="trim">
<%
    i = 0
    return_values = []
    if d.return_type.kind != 'void':
        if not annotations.is_argument_size(d.name, 'return'):
            return_values.append({ 't': d.return_type, 'val': 'result', 'free': annotations.get_free_func(d.name, 'return') })
    arguments = []
%>
INCLUA_DECL GDCALLINGCONV godot_variant ${WRAPPER_NAME(d.name)}(godot_object *go, void *method_data, void *data, int argc, godot_variant **argv) {
% for a in d.arguments:
<%
    arguments.append(a.name)
    is_in = annotations.is_argument_in(d.name, a.name)
    is_out = annotations.is_argument_out(d.name, a.name)
    is_size = annotations.is_argument_size(d.name, a.name)
    if not is_out and is_size:
        continue
    size = annotations.get_array_size(d.name, a.name)
    param_size = 'size_t ' + size if (size and size in (a.name for a in d.arguments)) else ''
    is_array = size or annotations.is_array(d.name, a.name)
    if is_out and not is_size:
        return_values.append({
            't': a.type.remove_pointer(),
            'val': a.name,
            'size': 'result' if size == 'return' else size,
            'free': annotations.get_free_func(d.name, a.name)
        })
%>\
    % if is_out and not is_in:
<% arguments[-1] = '&' + a.name %>\
    ${typed_declaration(a.type.remove_pointer().spelling, a.name)};
    % else:
    ${arg_from_variant(a.type, typed_declaration(a.type.spelling, a.name), "argv[{}]".format(i), size=param_size, is_array=is_array)}
<% i += 1 %>\
    % endif
% endfor
% if d.return_type.kind == 'void':
    ${d.name}(${', '.join(arguments)});
% else:
    ${d.return_type.spelling} result = ${d.name}(${', '.join(arguments)});
% endif
% if not return_values:
    return nil_variant();
% elif len(return_values) == 1:
    godot_variant var = ${to_variant_for(**return_values[0])};
    % if return_values[0].get('free'):
    ${return_values[0]['free']}(${return_values[0]['val']});
    % endif
    return var;
% else:
    godot_array return_values;
    api->godot_array_new(&return_values);
    % for ret in return_values:
    {
        godot_variant ret = ${to_variant_for(**ret)};
        api->godot_array_append(&return_values, &ret);
        api->godot_variant_destroy(&ret);
    }
    % endfor
    godot_variant var;
    api->godot_variant_new_array(&var, &return_values);
    api->godot_array_destroy(&return_values);
    return var;
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
godot_method_bind *Object_get_meta = nullptr;
godot_method_bind *Object_set_meta = nullptr;
godot_method_bind *Object_set_script = nullptr;
godot_method_bind *Reference_reference = nullptr;
godot_method_bind *Reference_unreference = nullptr;
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
typedef void (*FreeFunc)(void *);
struct RecordHelper {
    RecordHelper() : free_func(nullptr), ptr(nullptr) {}
    static RecordHelper *from_object(godot_object *go) {
        return (RecordHelper *) nativescript_api->godot_nativescript_get_userdata(go);
    }
    bool owns_data() {
        return free_func != nullptr;
    }
    void free_ptr() {
        if (ptr && free_func) {
            free_func(ptr);
        }
    }
    template<typename T>
    void set(const T *value, FreeFunc new_free_func) {
        free_ptr();
        if (new_free_func == api->godot_free) {
            ptr = api->godot_alloc(sizeof(T));
            memcpy(ptr, value, sizeof(T));
        }
        else {
            ptr = (void *) value;
        }
        free_func = new_free_func;
    }
    // fields
    void *ptr;
    FreeFunc free_func;
};

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
    StringHelper(godot_string gs) : gs(gs), gcs_valid(false) {}
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

template<typename T> T *buffer_from_pool_byte_array(godot_pool_byte_array *byte_array, size_t *out_size) {
    size_t size = api->godot_pool_byte_array_size(byte_array) / sizeof(T);
    if (T *buffer = (T *) api->godot_alloc(size * sizeof(T))) {
        godot_pool_byte_array_read_access *read = api->godot_pool_byte_array_read(byte_array);
        memcpy(buffer, api->godot_pool_byte_array_read_access_ptr(read), size * sizeof(T));
        api->godot_pool_byte_array_read_access_destroy(read);
        *out_size = size;
        return buffer;
    }
    else {
        LOG_ERROR("Failed allocating memory");
        *out_size = 0;
        return nullptr;
    }
}

template<typename T> T *buffer_from_pool_int_array(godot_pool_int_array *int_array, size_t *out_size) {
    size_t size = api->godot_pool_int_array_size(int_array);
    if (T *buffer = (T *) api->godot_alloc(size * sizeof(T))) {
        if (std::is_same<T, godot_int>::value) {
            godot_pool_int_array_read_access *read = api->godot_pool_int_array_read(int_array);
            const godot_int *int_ptr = api->godot_pool_int_array_read_access_ptr(read);
            memcpy(buffer, int_ptr, size * sizeof(T));
            api->godot_pool_int_array_read_access_destroy(read);
        }
        else {
            for (size_t i = 0; i < size; i++) {
            buffer[i] = (T) api->godot_pool_int_array_get(int_array, i);
            }
        }
        *out_size = size;
        return buffer;
    }
    else {
        LOG_ERROR("Failed allocating memory");
        *out_size = 0;
        return nullptr;
    }
}

template<typename T> T *buffer_from_pool_real_array(godot_pool_real_array *real_array, size_t *out_size) {
    size_t size = (size_t) api->godot_pool_real_array_size(real_array);
    if (T *buffer = (T *) api->godot_alloc(size * sizeof(T))) {
        if (std::is_same<T, godot_real>::value) {
            godot_pool_real_array_read_access *read = api->godot_pool_real_array_read(real_array);
            const godot_real *real_ptr = api->godot_pool_real_array_read_access_ptr(read);
            memcpy(buffer, real_ptr, size * sizeof(T));
            api->godot_pool_real_array_read_access_destroy(read);
        }
        else {
            for (size_t i = 0; i < size; i++) {
                buffer[i] = (T) api->godot_pool_real_array_get(real_array, i);
            }
        }
        *out_size = size;
        return buffer;
    }
    else {
        LOG_ERROR("Failed allocating memory");
        *out_size = 0;
        return nullptr;
    }
}

const char **buffer_from_pool_string_array(godot_pool_string_array *string_array, size_t *out_size) {
    size_t size = api->godot_pool_string_array_size(string_array);
    if (const char **buffer = (const char **) api->godot_alloc(size * sizeof(char *))) {
        for (size_t i = 0; i < size; i++) {
            StringHelper helper = api->godot_pool_string_array_get(string_array, i);
            buffer[i] = helper.strdup();
        }
        *out_size = size;
        return buffer;
    }
    else {
        LOG_ERROR("Failed allocating memory");
        *out_size = 0;
        return nullptr;
    }
}

template<typename T> INCLUA_DECL T object_from_variant(const godot_variant *var);
template<typename T> T *buffer_from_object_array(godot_array *array, size_t *out_size) {
    size_t size = api->godot_array_size(array);
    if (T *buffer = (T *) api->godot_alloc(size * sizeof(T))) {
        for (size_t i = 0; i < size; i++) {
            godot_variant var = api->godot_array_get(array, i);
            buffer[i] = object_from_variant<T>(&var);
        }
        *out_size = size;
        return buffer;
    }
    else {
        LOG_ERROR("Failed allocating memory");
        *out_size = 0;
        return nullptr;
    }
}
template<typename T> INCLUA_DECL T object_pointer_from_variant(const godot_variant *var);
template<typename T> T *buffer_from_object_pointer_array(godot_array *array, size_t *out_size) {
    size_t size = api->godot_array_size(array);
    if (T *buffer = (T *) api->godot_alloc(size * sizeof(T))) {
        for (size_t i = 0; i < size; i++) {
            godot_variant var = api->godot_array_get(array, i);
            buffer[i] = object_pointer_from_variant<T>(&var);
        }
        *out_size = size;
        return buffer;
    }
    else {
        LOG_ERROR("Failed allocating memory");
        *out_size = 0;
        return nullptr;
    }
}

template<typename T> struct IntArrayHelper {
    IntArrayHelper(const godot_variant *var) {
        switch (api->godot_variant_get_type(var)) {
            case GODOT_VARIANT_TYPE_POOL_BYTE_ARRAY: {
                godot_pool_byte_array arr = api->godot_variant_as_pool_byte_array(var);
                buffer = buffer_from_pool_byte_array<T>(&arr, &size);
                api->godot_pool_byte_array_destroy(&arr);
                break;
            }
            default: {
                godot_pool_int_array arr = api->godot_variant_as_pool_int_array(var);
                buffer = buffer_from_pool_int_array<T>(&arr, &size);
                api->godot_pool_int_array_destroy(&arr);
                break;
            }
        }
    }
    T *extract() {
        T *ptr = buffer;
        buffer = nullptr;
        return ptr;
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
                buffer = buffer_from_pool_byte_array<T>(&arr, &size);
                api->godot_pool_byte_array_destroy(&arr);
                break;
            }
            default: {
                godot_pool_real_array arr = api->godot_variant_as_pool_real_array(var);
                buffer = buffer_from_pool_real_array<T>(&arr, &size);
                api->godot_pool_real_array_destroy(&arr);
                break;
            }
        }
    }
    ~FloatArrayHelper() {
        if (buffer) api->godot_free(buffer);
    }
    T *extract() {
        T *ptr = buffer;
        buffer = nullptr;
        return ptr;
    }
    // fields
    T *buffer;
    size_t size;
};

struct StringArrayHelper {
    StringArrayHelper(const godot_variant *var) {
        godot_pool_string_array arr = api->godot_variant_as_pool_string_array(var);
        buffer = buffer_from_pool_string_array(&arr, &size);
        api->godot_pool_string_array_destroy(&arr);
    }
    ~StringArrayHelper() {
        if (buffer) api->godot_free(buffer);
    }
    const char **extract() {
        const char **ptr = buffer;
        buffer = nullptr;
        return ptr;
    }
    // fields
    const char **buffer;
    size_t size;
};

template<typename T> struct ObjectArrayHelper {
    ObjectArrayHelper(const godot_variant *var) {
        if (api->godot_variant_get_type(var) == GODOT_VARIANT_TYPE_ARRAY) {
            godot_array arr = api->godot_variant_as_array(var);
            if (std::is_pointer<T>::value) {
                buffer = buffer_from_object_pointer_array<T>(&arr, &size);
            }
            else {
                buffer = buffer_from_object_array<T>(&arr, &size);
            }
            api->godot_array_destroy(&arr);
        }
        else {
            buffer = nullptr;
            size = 0;
        }
    }
    ~ObjectArrayHelper() {
        if (buffer) api->godot_free(buffer);
    }
    T *extract() {
        T *ptr = buffer;
        buffer = nullptr;
        return ptr;
    }
    // fields
    T *buffer;
    size_t size;
};

INCLUA_DECL godot_variant get_meta(godot_object *go, const char *rawkey) {
    StringHelper key = rawkey;
    const void *args[] = { &key.gs };
    godot_variant var;
    api->godot_method_bind_ptrcall(Object_get_meta, go, args, &var);
    return var;
}
INCLUA_DECL void set_meta(godot_object *go, const char *rawkey, const godot_variant *var) {
    StringHelper key = rawkey;
    const void *args[] = { &key.gs, var };
    api->godot_method_bind_ptrcall(Object_set_meta, go, args, nullptr);
}

INCLUA_DECL void reference(godot_object *go) {
    if (go) {
        godot_bool result;
        api->godot_method_bind_ptrcall(Reference_reference, go, NULL, &result);
    }
}
INCLUA_DECL void unreference(godot_object *go) {
    if (go) {
        godot_bool result;
        api->godot_method_bind_ptrcall(Reference_unreference, go, NULL, &result);
    }
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
</%text>

INCLUA_DECL GDCALLINGCONV godot_variant call_function_as_method(godot_object *go, void *method_data, void *data, int argc, godot_variant **argv) {
    godot_variant *wrapper_argv[argc + 1];
    godot_variant self;
    api->godot_variant_new_object(&self, go);
    wrapper_argv[0] = &self;
    for (int i = 0; i < argc; i++) {
        wrapper_argv[i + 1] = argv[i];
    }
    auto func = (GDCALLINGCONV godot_variant (*)(godot_object *, void *, void *, int, godot_variant **)) method_data;
    return func(Global, nullptr, nullptr, argc + 1, wrapper_argv);
}

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
template<typename T> INCLUA_DECL godot_variant int_array_variant(const T *arr, size_t size) {
    godot_pool_int_array pool_array;
    api->godot_pool_int_array_new(&pool_array);
    api->godot_pool_int_array_resize(&pool_array, size);
    for (size_t i = 0; i < size; i++) {
        api->godot_pool_int_array_set(&pool_array, i, (godot_int) arr[i]);
    }
    godot_variant var;
    api->godot_variant_new_pool_int_array(&var, &pool_array);
    return var;
}
template<typename T> INCLUA_DECL godot_variant float_variant(T f) {
    godot_variant var;
    api->godot_variant_new_real(&var, f);
    return var;
}
template<typename T> INCLUA_DECL godot_variant float_array_variant(const T *arr, size_t size) {
    godot_pool_real_array pool_array;
    api->godot_pool_real_array_new(&pool_array);
    api->godot_pool_real_array_resize(&pool_array, size);
    for (size_t i = 0; i < size; i++) {
        api->godot_pool_real_array_set(&pool_array, i, (godot_real) arr[i]);
    }
    godot_variant var;
    api->godot_variant_new_pool_real_array(&var, &pool_array);
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
INCLUA_DECL godot_variant string_array_variant(const char **arr, size_t size) {
    godot_pool_string_array pool_array;
    api->godot_pool_string_array_new(&pool_array);
    api->godot_pool_string_array_resize(&pool_array, size);
    for (size_t i = 0; i < size; i++) {
        StringHelper helper = arr[i];
        api->godot_pool_string_array_set(&pool_array, i, &helper.gs);
    }
    godot_variant var;
    api->godot_variant_new_pool_string_array(&var, &pool_array);
    return var;
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
INCLUA_DECL godot_variant object_variant(const godot_object *go) {
    godot_variant var;
    api->godot_variant_new_object(&var, go);
    return var;
}
template<typename T> INCLUA_DECL godot_variant object_variant(const T& value, const godot_object *script) {
    godot_object *go = new_object_with_script(script);
    RecordHelper *helper = RecordHelper::from_object(go);
    helper->set(&value, api->godot_free);
    return object_variant(go);
}
template<typename T> INCLUA_DECL godot_variant object_variant(const T *value, const godot_object *script, FreeFunc free_func) {
    if (!value) return nil_variant();
    godot_object *go = new_object_with_script(script);
    RecordHelper *helper = RecordHelper::from_object(go);
    helper->set(value, free_func);
    return object_variant(go);
}
template<typename T> INCLUA_DECL godot_variant object_array_variant(const T *values, size_t size, const godot_object *script) {
    godot_array arr;
    api->godot_array_new(&arr);
    for (size_t i = 0; i < size; i++) {
        godot_variant obj_var = object_variant(values[i], script);
        api->godot_array_append(&arr, &obj_var);
    }
    godot_variant var;
    api->godot_variant_new_array(&var, &arr);
    return var;
}

///////////////////////////////////////////////////////////////////////////////
// Variant -> Data
///////////////////////////////////////////////////////////////////////////////
template<typename T> INCLUA_DECL T object_from_variant(const godot_variant *var) {
    if (api->godot_variant_get_type(var) != GODOT_VARIANT_TYPE_OBJECT) return {};
    godot_object *go = api->godot_variant_as_object(var);
    RecordHelper *helper = RecordHelper::from_object(go);
    return *((T *) helper->ptr);
}
template<typename T> INCLUA_DECL T object_pointer_from_variant(const godot_variant *var) {
    if (api->godot_variant_get_type(var) != GODOT_VARIANT_TYPE_OBJECT) return {};
    godot_object *go = api->godot_variant_as_object(var);
    RecordHelper *helper = RecordHelper::from_object(go);
    return (T) helper->ptr;
}

INCLUA_DECL int char_from_variant(const godot_variant *var) {
    switch (api->godot_variant_get_type(var)) {
        case GODOT_VARIANT_TYPE_NIL: return 0;
        case GODOT_VARIANT_TYPE_INT: return api->godot_variant_as_int(var);
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

template<typename T> INCLUA_DECL void set_int_array_from_variant(T& arr, const godot_variant *var) {
    if (arr) api->godot_free(arr);
    IntArrayHelper<typename std::remove_pointer<T>::type> helper = var;
    arr = helper.extract();
}
template<typename T, typename S> INCLUA_DECL void set_int_array_from_variant(T& arr, S& size, const godot_variant *var) {
    if (arr) api->godot_free(arr);
    IntArrayHelper<typename std::remove_pointer<T>::type> helper = var;
    arr = helper.extract();
    size = helper.size;
}

template<typename T> INCLUA_DECL void set_float_array_from_variant(T& arr, const godot_variant *var) {
    if (arr) api->godot_free(arr);
    FloatArrayHelper<typename std::remove_pointer<T>::type> helper = var;
    arr = helper.extract();
}
template<typename T, typename S> INCLUA_DECL void set_float_array_from_variant(T& arr, S& size, const godot_variant *var) {
    if (arr) api->godot_free(arr);
    FloatArrayHelper<typename std::remove_pointer<T>::type> helper = var;
    arr = helper.extract();
    size = helper.size;
}

template<typename T> INCLUA_DECL void set_string_array_from_variant(T& arr, const godot_variant *var) {
    if (arr) api->godot_free(arr);
    StringArrayHelper helper = var;
    arr = helper.extract();
}
template<typename T, typename S> INCLUA_DECL void set_string_array_from_variant(T& arr, S& size, const godot_variant *var) {
    if (arr) api->godot_free(arr);
    StringArrayHelper helper = var;
    arr = helper.extract();
    size = helper.size;
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
INCLUA_DECL godot_variant get_bound_object(godot_object *go, void *method_data, void *data) {
    const godot_object *obj = (const godot_object *) method_data;
    return object_variant(obj);
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
    % elif d.is_record():
    {  // ${d.spelling}
        godot_property_attributes attr = {
            GODOT_METHOD_RPC_MODE_DISABLED, GODOT_VARIANT_TYPE_OBJECT,
            GODOT_PROPERTY_HINT_NONE, godot_string(), GODOT_PROPERTY_USAGE_DEFAULT,
        };
        godot_property_get_func getter = { &get_bound_object, (void *) ${NATIVESCRIPT_NAME(d.name)}, NULL };
        godot_property_set_func setter = { NULL, NULL, NULL };
        nativescript_api->godot_nativescript_register_property(
            p_handle, "Global", "${d.name}",
            &attr, setter, getter
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
    LOG_ERROR_IF_FALSE(Object_get_meta = api->godot_method_bind_get_method("Object", "get_meta"));
    LOG_ERROR_IF_FALSE(Object_set_meta = api->godot_method_bind_get_method("Object", "set_meta"));
    LOG_ERROR_IF_FALSE(Object_set_script = api->godot_method_bind_get_method("Object", "set_script"));
    LOG_ERROR_IF_FALSE(Reference_reference = api->godot_method_bind_get_method("Reference", "reference"));
    LOG_ERROR_IF_FALSE(Reference_unreference = api->godot_method_bind_get_method("Reference", "unreference"));
    LOG_ERROR_IF_FALSE(NativeScript_set_class_name = api->godot_method_bind_get_method("NativeScript", "set_class_name"));
    LOG_ERROR_IF_FALSE(NativeScript_set_library = api->godot_method_bind_get_method("NativeScript", "set_library"));
}

GDN_EXPORT void godot_gdnative_terminate(godot_gdnative_terminate_options *options) {
% for d in oop.iter_types():
    inclua::unreference(${NATIVESCRIPT_NAME(d.name)});
% endfor
}

GDN_EXPORT void godot_nativescript_init(void *p_handle) {
% for d in oop.iter_types():
    inclua::${REGISTER_NAME(d.name)}(p_handle);
% endfor
    inclua::_global_register(p_handle);
}

} // extern "C"
#endif

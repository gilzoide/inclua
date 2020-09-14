"""
Handle namespace prefixes in C API.
"""

def get_namespace(name, namespace_prefixes):
    return next((prefix for prefix in namespace_prefixes if name.startswith(prefix)), None)

def canonicalize(name, namespace_prefixes):
    namespace = get_namespace(name, namespace_prefixes)
    return name[len(namespace):] if namespace else name

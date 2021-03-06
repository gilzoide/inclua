"""
Usage:
  inclua <input> [-i <pattern>...] [-n <namespace>...] [options] [-- <clang_args>...]
  inclua -h

Options:
  -i, --include=<include_pattern>
                          Only process headers with names that match any of the given regex patterns.
                          Matches are tested using `re.search`, so patterns are not anchored by default.
                          This may be used to avoid processing standard headers and dependencies headers.
  -t, --template <template>
                          Select target template for generating bindings. You can pass your own Mako
                          template files here.
                          Builtin templates: luajit. [default: luajit]
  -m, --module <module_name>
                          Explicitly set module name, instead of trying to find from input name.
                          Module name is used for library loading and should be the same as the shared library name.
  -n, --namespace=<namespace>
                          Namespace prefixes used in C declarations, used to remove the redundant prefix
                          in languages that support namespacing. 
  -d, --extra-definitions=<definitions_file>
                          JSON or YAML file with extra definitions about the API.
                          For LuaJIT, additional definitions should be Lua functions for metamethods like
                          __tostring, __new, __add etc, or other Lua definitions to be inserted into __index.
  --pod                   Don't create metatypes for struct definitions. By default, inclua will create
                          metatypes for structs and unions and try to populate __index and __gc
                          based on functions name and arguments.
  --skip-defines          By default, inclua will try compiling object-like macros looking for
                          constants, which may take long if your header has lots of them. Use this flag
                          to skip this step.
"""

import importlib
from pathlib import PurePath, Path
from signal import signal, SIGPIPE, SIG_DFL
from sys import stderr

import c_api_extract
from docopt import docopt
from mako.exceptions import TopLevelLookupException
from mako.lookup import TemplateLookup
from mako.template import Template
import yaml

from inclua.annotation import Annotations
from inclua.error import IncluaError
from inclua import namespace
from inclua.oop import OOP


BUILTIN_TEMPLATES = {
    'lua': "templates/lua.cpp.mako",
    'luajit': "templates/luajit.lua.mako",
    'gdnative': "templates/gdnative.cpp.mako",
}


def main():
    opts = docopt(__doc__)
    template_lookup = TemplateLookup(directories=[Path.cwd(), PurePath(__file__).parent], strict_undefined=True)
    template = opts.get('--template')
    template = BUILTIN_TEMPLATES.get(template, template)
    try:
        template = template_lookup.get_template(template)
    except TopLevelLookupException:
        stderr.write("Error: could not find template {!r}\n".format(template))
        return

    header = opts['<input>']
    definitions = c_api_extract.definitions_from_header(
        header,
        clang_args=opts['<clang_args>'],
        include_patterns=opts['--include'],
        type_objects=True,
        skip_defines=opts['--skip-defines'],
    )
    module_name = opts.get('--module') or PurePath(opts['<input>']).stem
    namespace_prefixes = opts.get('--namespace')
    annotations = Annotations()
    if opts.get('--extra-definitions'):
        with open(opts.get('--extra-definitions')) as f:
            annotations.update(yaml.safe_load(f) or {})
    # apply ignore annotations before doing any more processing
    definitions = [d for d in definitions if not annotations.should_ignore(d.name)]
    oop = OOP(definitions, namespace_prefixes, annotations, pod=opts.get('--pod'))

    def canonicalize(s):
        return namespace.canonicalize(s, namespace_prefixes)

    code = template.render(
        annotations=annotations,
        canonicalize=canonicalize,
        header=header,
        definitions=definitions,
        module_name=module_name,
        namespace_prefixes=namespace_prefixes,
        oop=oop,
    ).strip()

    signal(SIGPIPE, SIG_DFL)
    print(code)

if __name__ == '__main__':
    main()

"""
Usage:
  inclua <input> [-i <pattern>...] [-n <namespace>...] [options] [-- <clang_args>...]
  inclua -h

Options:
  -i, --include=<include_pattern>
                          Only process headers with names that match any of the given regex patterns.
                          Matches are tested using `re.search`, so patterns are not anchored by default.
                          This may be used to avoid processing standard headers and dependencies headers.
  -l, --language <language>
                          Select target language for bindings [default: luajit].
  -m, --module <module_name>
                          Explicitly set module name, instead of trying to find from input name.
                          Module name is used for library loading and should be the same as the shared library name.
  -n, --namespace=<namespace>
                          Namespace prefixes used in C declarations, used to remove the redundant prefix
                          in languages that support namespacing. 
  -d, --additional-definitions=<definitions_file>
                          JSON or YAML file with additional definitions for metatypes.
                          For LuaJIT, additional definitions should be Lua functions for metamethods like
                          __tostring, __new, __add etc, or other Lua definitions to be inserted into __index.
  --pod                   Don't create metatypes for struct definitions. By default, inclua will create
                          metatypes for structs and unions and try to populate __index and __gc
                          based on functions name and arguments.
"""

import importlib
from pathlib import PurePath
from signal import signal, SIGPIPE, SIG_DFL
from sys import stderr

import c_api_extract
from docopt import docopt
import yaml

from inclua.error import IncluaError
from inclua.metatype import Metatype


def main():
    opts = docopt(__doc__)
    language = opts.get('--language')
    try:
        generator = importlib.import_module('inclua.{}'.format(language))
    except ModuleNotFoundError:
        stderr.write("Error: Invalid target language {!r}. Must be one of 'luajit' or 'd'\n".format(language))
        return

    definitions = c_api_extract.definitions_from_header(
        opts['<input>'],
        clang_args=opts['<clang_args>'],
        include_patterns=opts['--include'],
        type_objects=True,
        include_source=getattr(generator, "INCLUDE_SOURCE", False),
        include_size=getattr(generator, "INCLUDE_SIZE", False),
        include_offset=getattr(generator, "INCLUDE_OFFSET", False),
    )
    module_name = opts.get('--module') or PurePath(opts['<input>']).stem
    if opts.get('--additional-definitions'):
        with open(opts.get('--additional-definitions')) as f:
            extra_definitions = yaml.safe_load(f)
    else:
        extra_definitions = {}
    metatypes = [] if opts.get('--pod') else Metatype.from_definitions(definitions, opts.get('--namespace'), extra_definitions)

    code = generator.generate(
        definitions,
        module_name,
        metatypes=metatypes,
        namespace_prefixes=opts.get('--namespace'),
    )
    signal(SIGPIPE, SIG_DFL)
    print(code)

if __name__ == '__main__':
    main()

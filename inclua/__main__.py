"""
Usage:
  inclua <input> [-m <module_name>] [-p <pattern>...] [-n <namespace>...] [-g] [-d <definitions_file> | --no-metatypes] [-- <clang_args>...]
  inclua -h

Options:
  -m <module_name>, --module <module_name>  Explicitly set module name, instead of trying to find from input name.
                                            Module name is used for library loading and should be the same as the shared library name.
  -p <pattern>, --pattern=<pattern>         Only process headers with names that match any of the given regex patterns.
                                            This may be used to avoid processing standard headers and dependencies headers.
  -n <namespace>, --namespace=<namespace>   Namespace prefixes used in C declarations, used to remove the redundant prefix
                                            in languages that support namespacing. 
  -g, --global                              Import definitions into the global C FFI namespace.
  -d <definitions_file>, --additional-definitions=<definitions_file>
                                            JSON or YAML file with additional definitions for metatypes.
                                            For LuaJIT, additional definitions should be Lua functions for metamethods like
                                            __tostring, __new, __add etc, or other Lua definitions to be inserted into __index.
  --no-metatypes                            Don't create metatypes for struct definitions. By default, inclua will create
                                            metatypes for structs and unions and try to populate __index and __gc
                                            based on functions name and arguments.
"""

from pathlib import PurePath
from signal import signal, SIGPIPE, SIG_DFL

import c_api_extract
from docopt import docopt
import yaml

from inclua import luajit


def main():
    opts = docopt(__doc__)
    definitions = c_api_extract.definitions_from_header(
        opts['<input>'], opts['<clang_args>'], opts['--pattern'])
    module_name = opts.get('--module') or PurePath(opts['<input>']).stem
    if opts.get('--additional-definitions'):
        with open(opts.get('--additional-definitions')) as f:
            additional_definitions = yaml.safe_load(f)
    else:
        additional_definitions = None
    code = luajit.generate(
        definitions,
        module_name,
        import_global=opts.get('--global'),
        generate_metatypes=not opts.get('--no-metatypes'),
        namespace_prefixes=opts.get('--namespace'),
        additional_definitions=additional_definitions,
    )
    signal(SIGPIPE, SIG_DFL)
    print(code)

if __name__ == '__main__':
    main()

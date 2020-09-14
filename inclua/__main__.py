"""
Usage:
  inclua <input> [-m <module_name>] [-g] [-t] [-p <pattern>...] [-- <clang_args>...]
  inclua -h

Options:
  -m <module_name>, --module <module_name>    Explicitly set module name, instead of trying to find from input name.
                                              Module name is used for output files naming.
  -p <pattern>, --pattern=<pattern>           Only process headers with names that match any of the given regex patterns.
                                              This may be used to avoid processing standard headers and dependencies headers.
  -g, --global                                Import C definitions into the global table.
  -t, --metatypes                             Create metatypes for struct definitions and try to populate __index and __gc
                                              based on functions name and arguments.
"""

from pathlib import PurePath
from signal import signal, SIGPIPE, SIG_DFL

import c_api_extract
from docopt import docopt

from inclua import luajit


def main():
    opts = docopt(__doc__)
    definitions = c_api_extract.definitions_from_header(
        opts['<input>'], opts['<clang_args>'], opts['--pattern'])
    module_name = opts.get('--module') or PurePath(opts['<input>']).stem
    code = luajit.generate(
        definitions,
        module_name,
        import_global=opts.get('--global'),
        generate_metatypes=opts.get('--metatypes'),
    )
    signal(SIGPIPE, SIG_DFL)
    print(code)

if __name__ == '__main__':
    main()


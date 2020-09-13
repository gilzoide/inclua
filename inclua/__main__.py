"""
Usage:
  inclua <input> [-m <module_name>] [-g] [-- <clang_args>...]
  inclua -h

Options:
  -m <module_name>, --module <module_name>    Explicitly set module name, instead of trying to find from input name.
                                              Module name is used for output files naming.
  -g, --global                                Import C definitions into the global table.
"""

from pathlib import PurePath
from signal import signal, SIGPIPE, SIG_DFL

import c_api_extract
from docopt import docopt

from inclua import luajit


def main():
    opts = docopt(__doc__)
    definitions = c_api_extract.definitions_from_header(
        opts['<input>'], opts['<clang_args>'])
    module_name = opts.get('--module') or PurePath(opts['<input>']).stem
    code = luajit.generate(definitions, module_name, opts.get('--global'))
    signal(SIGPIPE, SIG_DFL)
    print(code)

if __name__ == '__main__':
    main()


## Copyright 2016 Gil Barbosa Reis <gilzoide@gmail.com>
# This file is part of Inclua.
#
# Inclua is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Inclua is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Inclua.  If not, see <http://www.gnu.org/licenses/>.

from .Generator import Generator
from .Error import IncluaError
import yaml
import argparse
import sys
import importlib

def main ():
    """Generates the bindings from a YAML configuration file, that follows the
    same rules as using the library directly"""

    parser = argparse.ArgumentParser (description = r"""
Inclua Copyright (c) 2016 Gil Barbosa Reis.
Inclua is a binding code generator, that binds (for now, only) C to Lua.""",
            epilog = r"""
Any bugs should be reported to <gilzoide@gmail.com>""",
            formatter_class = argparse.RawDescriptionHelpFormatter)
    parser.add_argument ('input', action = 'store', type = argparse.FileType ('r'),
            help = "input YAML configuration file")
    parser.add_argument ('-o', '--output', action = 'store',
            help = "output wrapper file, stdout if not present")
    parser.add_argument ('-l', '--language', action = 'store', required = True,
            help = "binding target language")
    parser.add_argument ('clang_args', nargs = argparse.REMAINDER,
            help = "arguments to clang parser, useful for \"-Dname\" and \"-Dname=val\" macros")

    cli_opts = parser.parse_args ()
    # assert generator exists
    lang = cli_opts.language
    try:
        importlib.import_module ('inclua.{}'.format (lang))
    except:
        try:
            importlib.import_module (lang)
        except:
            raise IncluaError ("Language {!r} not found in inclua, nor as an import in current directory".format (lang))

    yaml_docs = yaml.load_all (cli_opts.input)

    # process header YAML doc, the general stuff
    try:
        header_conf = next (yaml_docs)
        G = Generator (header_conf['module'])
        for h in header_conf['headers']:
            G.add_header (h)
    except:
        raise IncluaError ("YAML header configuration should have at least 'module' and 'headers' fields")
    if header_conf.get ('ignore'):
        for i in header_conf['ignore']:
            G.ignore (i)
    if header_conf.get ('ignore_regex'):
        for i in header_conf['ignore_regex']:
            G.ignore_regex (i)
    if header_conf.get ('rename'):
        for target, sub in header_conf['rename'].items ():
            G.rename (target, sub)
    if header_conf.get ('rename_regex'):
        for patt, sub in header_conf['rename_regex'].items ():
            G.rename_regex (patt, sub)
    if header_conf.get ('clang_args'):
        G.extend_clang_args (header_conf['clang_args'])
    G.extend_clang_args (cli_opts.clang_args)

    # process definition notes YAML doc if present, or use header one
    try:
        definitions_conf = next (yaml_docs)
    except:
        # get rid of header stuff
        del header_conf['module']
        del header_conf['headers']
        if header_conf.get ('ignore'):
            del header_conf['ignore']
        if header_conf.get ('ignore_regex'):
            del header_conf['ignore_regex']
        if header_conf.get ('rename'):
            del header_conf['rename']
        if header_conf.get ('rename_regex'):
            del header_conf['rename_regex']
        if header_conf.get ('clang_args'):
            del header_conf['clang_args']
        definitions_conf = header_conf
    for target, info in definitions_conf.items ():
        if info == 'ignore':
            G.ignore (target)
        elif info == 'scope':
            G.scope (target)
        else:
            try:
                rename = info['rename']
                G.rename (target, rename)
                if info.get ('notes'):
                    notes = info['notes']
                    G.note (target, notes)
            except:
                G.note (target, info)
    
    # and generate, that's what we're here for ;]
    G.generate (cli_opts.language, cli_opts.output or sys.stdout)

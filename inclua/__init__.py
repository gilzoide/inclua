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
from .GeneralInfo import version, get_clang_version
from .Visitor import Visitor
import yaml
import argparse
import sys
import importlib

# define package __version__ string
__version__ = version

class VersionPrinter (argparse.Action):
    """Argparse Action that prints inclua version"""
    def __call__ (self, parser, namespace, values, option_string):
        print (version)
        sys.exit ()

class ClangVersion (argparse.Action):
    """Argparse Action that prints the used clang version"""
    def __call__ (self, parser, namespace, values, option_string):
        print (get_clang_version () or "[inclua] Couldn't find clang version")
        sys.exit ()

class DocPrinter (argparse.Action):
    """Argparse Action that prints language generators' docs"""
    def __call__ (self, parser, namespace, values, option_string):
        lang = values[0]
        _find_lang (lang)
        print (Generator.get_doc (lang))
        sys.exit ()

def _find_lang (lang):
    """Find the language by importing a module from inclua, or current directory.
    Raises if not found"""
    try:
        importlib.import_module ('inclua.{}'.format (lang))
    except:
        try:
            importlib.import_module (lang)
        except:
            raise IncluaError ("Language {!r} not found in inclua, nor as an import in current directory".format (lang))

def _include_yaml (stream, G):
    """Process a YAML file and register everything in Generator `G`. May be
    called recursively for included YAML files."""
    yaml_docs = yaml.load_all (stream)

    # process header YAML doc, the general stuff
    try:
        header_conf = next (yaml_docs)
        if not G.mod_name:
            G.set_module_name (header_conf['module'])
    except yaml.scanner.ScannerError as ex:
        raise IncluaError ("YAML parse error: " + str (ex))
    except KeyError:
        raise IncluaError ("YAML header configuration should have at least 'module' and 'headers' fields")
    if header_conf.get ('clang_args'):
        G.extend_clang_args (header_conf['clang_args'])
    if header_conf.get ('headers'):
        for h in header_conf['headers']:
            G.add_header (h)
    # include other YAML files. 
    if header_conf.get ('include'):
        for f_name in header_conf['include']:
            with open (Visitor.find_path (f_name, G.clang_args), 'r') as f:
                _include_yaml (f, G)
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

    # process definition notes YAML doc if present, or use header one
    try:
        definitions_conf = next (yaml_docs)
    except:
        # get rid of header stuff
        def _delete_if_present (conf, key):
            if conf.get (key):
                del conf[key]
        _delete_if_present (header_conf, 'module')
        _delete_if_present (header_conf, 'headers')
        _delete_if_present (header_conf, 'include')
        _delete_if_present (header_conf, 'ignore')
        _delete_if_present (header_conf, 'ignore_regex')
        _delete_if_present (header_conf, 'rename')
        _delete_if_present (header_conf, 'rename_regex')
        _delete_if_present (header_conf, 'clang_args')
        # now header is the definition configuration
        definitions_conf = header_conf
    # if there are extra definitions, process them
    if definitions_conf:
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
    parser.add_argument ('-v', '--version', nargs = 0, action = VersionPrinter,
            help = "prints program version")
    parser.add_argument ('-clv', '--clang-version', nargs = 0, action = ClangVersion,
            help = "prints used clang version")
    parser.add_argument ('-hl', '--help-language', nargs = 1, action = DocPrinter,
            help = "prints the language generator documentation", metavar = 'LANGUAGE')
    parser.add_argument ('-o', '--output', action = 'store',
            help = "output wrapper file, stdout if not present")
    parser.add_argument ('-l', '--language', action = 'store', required = True,
            help = "binding target language")
    parser.add_argument ('clang_args', nargs = argparse.REMAINDER,
            help = "arguments to clang parser, useful for \"-Dname\"/\"-Dname=val\" macros and \"-Iinclude_directory\" flags (which will be used by inclua to look for the headers)")

    cli_opts = parser.parse_args ()
    # assert generator exists
    _find_lang (cli_opts.language)

    # start with the root YAML file
    G = Generator ()
    G.extend_clang_args (cli_opts.clang_args)
    _include_yaml (cli_opts.input, G)

    # and generate, that's what we're here for ;]
    G.generate (cli_opts.language, cli_opts.output or sys.stdout)

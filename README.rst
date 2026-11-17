Inclua
======
Wrapper generator from C to scripting languages, currently supporting LuaJIT_ FFI only.
It uses clang_ via c_api_extract_ for parsing and understanding C header files.

By deafult generates metatypes_ for struct and union definitions and deduces ``__gc``
and other methods from C functions names and parameters, included in the ``__index`` table.
**inclua** also supports adding native Lua definitions for any metamethods and other definitions
for metatypes, reading them verbatim from a YAML or JSON file.

.. _LuaJIT: https://luajit.org/
.. _clang: https://pypi.org/project/clang/
.. _c_api_extract: https://github.com/gilzoide/c_api_extract-py
.. _metatypes: https://luajit.org/ext_ffi_api.html#ffi_metatype


Installing
----------
**inclua** is available on PyPI_ and may be installed using ``pip``::

  $ pip install inclua

.. _PyPI: https://pypi.org/project/inclua/


Usage
-----
On your shell::

    $ inclua <input> [-i <pattern>...] [-n <namespace>...] [options] [-- <clang_args>...]

Check out the help for more information on arguments::

    $ inclua -h


Check out the ``examples`` folder and csfml-luajit_ for examples of usage.

.. _csfml-luajit: https://github.com/gilzoide/csfml-luajit


TODO
----
- Try matching both typedef and struct|union name when searching for methods
- Add support for generating Lua C bindings
- Add more examples and document additional definitions input format
- Test on Windows

Inclua
======
Wrapper generator from C to scripting languages, currently supporting LuaJIT_ FFI only.
This uses clang_ via c_api_extract_ for parsing and understanding C header files.

.. _LuaJIT: https://luajit.org/
.. _clang: https://pypi.org/project/clang/
.. _c_api_extract: https://pypi.org/project/c-api-extract/

Usage
-----
On your shell::

    $ inclua <input> [-m <module_name>] [-p <pattern>...] [-n <namespace>...] [-g] [--no-metatypes] [-- <clang_args>...]

Check out the help for more information on arguments::

    $ inclua -h



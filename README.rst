Inclua
======
Wrapper generator from C to scripting languages, currently supporting LuaJIT_ FFI only.
It uses clang_ via c_api_extract_ for parsing and understanding C header files.

.. _LuaJIT: https://luajit.org/
.. _clang: https://pypi.org/project/clang/
.. _c_api_extract: https://github.com/gilzoide/c_api_extract-py


Installing
----------
**inclua** is available on PyPI_ and may be installed using ``pip``::

  $ pip install inclua

.. _PyPI: https://pypi.org/project/inclua/


Usage
-----
On your shell::

    $ inclua <input> [-m <module_name>] [-p <pattern>...] [-n <namespace>...] [-g] [-d <definitions_file> | --no-metatypes] [-- <clang_args>...]

Check out the help for more information on arguments::

    $ inclua -h


It is recommended to pass ``-I <path to clang headers>`` to *clang* to correctly
include some standard headers like **stddef.h** and **stdbool.h**.

Check out the ``examples`` folder for an example of usage.

Inclua
======
Wrapper generator for programming languages, INitially for binding C to LUA.
Implemented as a Lua library for portability, dinamicity and flexibility, as
new language binders can be easily added. Using libclang so that that we don't
need to worry about C/C++ parsing/preprocessing.


Installing
----------
Using LuaRocks_ (preferred way)::

    $ luarocks make

Or directly with CMake_::

    $ mkdir build
    $ cd build
    $ cmake ..
    $ make
    $ make install

.. _LuaRocks: https://luarocks.org/
.. _CMake: http://cmake.org/

Using directly from Lua
--------------------------
Require, generate!

.. code:: lua

    -- File wrapper_generator.lua
    local inclua = require 'inclua'
    local code = inclua.generate("module_name",  -- Module name
                                 "lua",          -- Target language
                                 {"module.h"},   -- Header files to process
                                 {},             -- Arguments to libclang parser
                                 {})             -- Notes about your API
    print(code)

On your shell::

    $ lua wrapper_generator.lua > wrapper.cpp


Using the standalone
--------------------
Define, generate!

.. code:: yaml

    # File wrapper_generator.yml
    module : module_name
    headers :
      - module.h

    --- # optional YAML document separation, to avoid name clashes with predefined fields
    # anotate your arrays, output arguments, ignore symbols, rename stuff...

On your shell::

    $ inclua -o wrapper.cpp -l lua wrapper_generator.yml


Tutorial
--------
Tutorials on creating wrappers, either using the lua lib or the standalone
YAML version, are available in the tutorial_.

.. _tutorial: https://github.com/gilzoide/inclua/blob/master/tutorial/index.rst

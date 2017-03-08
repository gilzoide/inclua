Inclua
======
Wrapper generator for programming languages, INitially for binding C to LUA.
Implemented as a Python library for portability, dinamicity and flexibility, as
new language binders can be easily added. Using libclang so that that we don't
need to worry about C/C++ parsing/preprocessing.


Using directly from python
--------------------------
Import, setup, generate!

.. code:: python

    # File wrapper_generator.py
    from inclua import *
    import inclua.lua # register Lua generator

    my_module = Generator ('module_name')
    my_module.add_header ('module.h') # at least one. It can be a '.c' file as well
    # anotate your arrays, output arguments, ignore symbols, rename stuff...
    my_module.generate ('lua')

On your shell::

    $ python wrapper_generator.py


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
Tutorials on creating wrappers, either using the python lib or the standalone
YAML version, and for creating **Generators** yourself, are available in the
tutorial_.

.. _tutorial: https://github.com/gilzoide/inclua/blob/master/tutorial/index.rst

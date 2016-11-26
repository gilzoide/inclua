Inclua
======
Wrapper generator for scripting languages, INitially for binding C to LUA.
Implemented as a Python library for portability, dinamicity and flexibility, as
new language binders can be easily added. Using libclang so that that we don't
need to worry about C/C++ parsing/preprocessing.


Using
-----
Import, setup, generate!

```python
from inclua import *

my_module = Generator ('module_name')
my_module.add_header ('module.h') # at least one. It can be a '.c' file as well
# anotate your arrays, output arguments, ignore symbols, rename stuff...
my_module.generate ('lua')
```




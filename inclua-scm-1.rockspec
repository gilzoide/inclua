package = 'inclua'
version = 'scm-1'
source = {
	url = 'git://github.com/gilzoide/inclua',
}
description = {
	summary = 'C/C++ to other languages wrapper generator, INitialy for binding C to LUA',
	detailed = [[
Wrapper generator for programming languages, INitially for binding C to LUA.
Implemented as a Lua library for portability, dinamicity and
flexibility, as new language binders can be easily added. Using libclang so
that that we don't need to worry about C/C++ parsing/preprocessing.
]],
	license = 'GPLv3',
	maintainer = 'gilzoide <gilzoide@gmail.com>'
}
dependencies = {
	'lua >= 5.2',
	'lpeglabel',
	'penlight',
	'molde',
}
build = {
	type = 'cmake',
	variables = {
		CMAKE_INSTALL_PREFIX = '$(PREFIX)',
		LUADIR = '$(LUADIR)',
		LIBDIR = '$(LIBDIR)',
		BINDIR = '$(BINDIR)',
		TEMPLATE_PATH_PREFIX = '$(CONFDIR)',
	},
}

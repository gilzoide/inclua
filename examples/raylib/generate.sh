#!/bin/sh

# change `clang_headers` to the right location for your installation
clang_headers='-I /usr/lib/clang/*/include'
inclua include_raylib.h -m raylib -p raylib -d extras.yml -- $clang_headers > c_raylib.lua

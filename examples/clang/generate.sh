#!/bin/sh

# change `clang_headers` to the right location for your installation
clang_headers='-I /usr/lib/clang/*/include'
inclua clang.h -m clang -n clang_ -n CX -p clang-c -g -d extras.yml -- $clang_headers > clang.lua

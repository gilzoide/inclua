#!/bin/sh

inclua include_allegro.h -m allegro -i allegro -n al_ -d extras.yml > allegro.lua
sed -i 's/time_t/unsigned long/' allegro.lua

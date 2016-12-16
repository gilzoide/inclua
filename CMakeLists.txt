# CMake de teste, pra ver se os módulos do CMake estão funcionando certo.
project (teste)

cmake_minimum_required(VERSION 2.6)
set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/build_systems")

find_package (Inclua REQUIRED)
include (${INCLUA_USE_FILE})

inclua_add_module (teste lua teste.yml)

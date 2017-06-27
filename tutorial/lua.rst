Gerando wrappers em python
==========================
**Inclua** é uma biblioteca de lua, e portanto pode ser usado como tal!

Passo a passo:

#. importar o módulo **inclua**
#. definir os *headers* a serem processados, a linguagem alvo, flags para a
   libclang e informações necessárias sobre a API (Notas_)
#. gerar!

.. _Notas: notas.rst

.. code:: lua

    -- 1. importar
    local inclua = require 'inclua'

    -- 2. definir headers, linguagem alvo, flags para a libclang e
    -- informações sobre a API
    local nome_do_modulo = 'nome_do_módulo'
    local headers = {'meu_header.h'}
    local linguagem_alvo = 'lua'
    -- é uma boa ideia incluir o caminho dos headers do clang, pra ele sacar `size_t`
    local clang_args = {"-I/usr/lib/clang/3.9.0/include"}
    local notas = {
        ignore = {'modulo_malloc'},
        ignore_pattern = {'_.+'},
        rename = {modulo_getXY = 'get_xy'},
        rename_pattern = {['^modulo_'] = ''},

        modulo_somaVetor = {'array[arg2] in', 'size'},
    }

    # 3. partiu gerar =]
    print(inclua.generate(nome_do_modulo, linguagem_alvo, headers, clang_args, notas))

E gere pelo lua

.. code:: bash

    # 3 ainda. gera por favor
    $ lua > saida.cpp

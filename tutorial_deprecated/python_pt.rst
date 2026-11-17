Gerando wrappers em python
==========================
**Inclua** é uma biblioteca de python, e portanto pode ser usado como tal!

Passo a passo:

1. importar o módulo **inclua** e módulo da linguagem alvo
2. criar um **Generator**
3. definir os *headers* a serem processados
4. definir as informações necessárias (Notas_)
5. gerar!

.. _Notas: notas.rst

.. code:: python

    # 1. importar
    from inclua import Generator
    # Se linguagem alvo for builtin do inclua, ela estará em um submódulo: importe-o
    # Caso contrário, registre a linguagem e sua função geradora usando `Generator.add_generator`
    import inclua.linguagem_escolhida

    # 2. criar um Generator, já com o nome do módulo (que é necessário)
    gen = Generator ('nome_do_módulo')

    # é uma boa ideia incluir o caminho dos headers do clang, pra ele sacar `size_t`
    gen.set_clang_args (["-I/usr/lib/clang/3.9.0/include"])
    
    # 3. definir os headers. Note que pode ser um arquivo .c também, desde que esse seja compilado junto
    gen.add_header ('meu_header.h')

    # 4. informações sobre o módulo, e como tratar suas definições.
    # Aqui é possível ignorar funções/structs/enums, renomeá-los, e anotar se
    # argumentos para uma função são argumentos de saída, ou se são vetores
    # (pra conversão do tipo nativo da linguagem destino), e se esses devem ser
    # excluídos da memória, dentre outros.
    gen.ignore_regex ('_.+')
    gen.rename_regex ('^modulo_', '')

    gen.ignore ('modulo_malloc')

    gen.note ('modulo_getXY', ['in', 'out', 'out'])
    gen.rename ('modulo_getXY', 'get_xy')

    gen.note ('modulo_somaVetor', ['array[arg2] in', 'size'])


    # 5. partiu gerar =]
    gen.generate ('linguagem_escolhida', 'arquivo_de_saída')

E gere pelo python

.. code:: bash

    # 5 ainda. gera por favor
    $ python script.py

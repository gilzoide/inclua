Gerando wrappers usando YAML
============================
Uma alternativa a criar um script em python pra gerar código é descrever seu
módulo usando YAML_ e usar o comando **inclua**. Para ajuda sobre como usar
o comando, rode em seu shell::

    $ inclua -h

.. _YAML: http://yaml.org/

Passo a passo:

1. definir nome do módulo
2. definir os *headers* a serem processados
3. definir informações gerais, como símbolos ignorados e renomeações
4. opcionalmente separar o documento YAML, para possibilitar o uso de símbolos
   reconhecidos por **inclua** como símbolos do código processado
5. definir as informações necessárias
6. gerar!

.. code:: yaml

    # 1. nome
    module : nome_do_módulo

    # 2. definir os headers. Note que pode ser um arquivo .c também, desde que esse seja compilado junto
    headers :
      - meu_header.h

    # 3. informações gerais
    ignore_regex :
      - _.+

    rename_regex :
      '^modulo_' : ''

    # é uma boa ideia incluir o caminho dos headers do clang, pra ele sacar `size_t`
    clang_args :
      - "-I/usr/lib/clang/3.9.0/include"

    # 4. separe o documento YAML, se quiser/precisar
    ---

    # 5. informações sobre o módulo, e como tratar suas definições.
    # Aqui é possível ignorar funções/structs/enums, renomeá-los, e anotar se
    # argumentos para uma função são argumentos de saída, ou se são vetores
    # (pra conversão do tipo nativo da linguagem destino), e se esses devem ser
    # excluídos da memória, dentre outros.
    modulo_malloc : ignore

    modulo_getXY :
      rename: get_xy
      notes: [in, out, out]

    modulo_somaVetor :
      - array[arg2] in
      - size

E gere pelo comando **inclua**

.. code:: bash

    # 6. partiu gerar =]
    $ inclua -o arquivo_de_saída -l linguagem_escolhida arquivo.yml

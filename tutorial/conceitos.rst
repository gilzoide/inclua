Como Inclua funciona?
=====================
Inclua é uma biblioteca escrita em Python para geração automática de código
*wrapper* ligando C/C++ a alguma outra linguagem, geralmente de *script* como
Lua, Python ou Ruby.

Para isso, **inclua** utiliza a `libclang`_ para realizar
a leitura e compreensão de código escrito em C, e transformar em objetos
Python fáceis de manipular e com a informação necessária para criar
*wrappers*.

.. _libclang: http://clang.llvm.org/


Classes e conceitos importantes
-------------------------------
**Generator (Gerador)**
    *Generator* é a classe que gerencia a geração de código. Ela mantém as
    informações coletadas sobre declarações importantes do código C processado
    e sobre o que fazer com elas.

    Diferentes linguagens alvo podem ser suportadas, bastando que sejam
    registradas pelo nome, e sua função geradora. Funções geradoras recebem a
    instância do *Generator*, e devem retornar uma *string* com o código
    *wrapper*. Para facilitar a criação de funções geradoras, foi criada a
    classe `Visitor`_, descrito abaixo.

    Informações vitais para o uso de um *Generator* são o nome do módulo a ser
    criado, e os nomes dos arquivos contendo os códigos a serem processados.

    Informações adicionais contemplam:

    - Flags a serem passadas para a *libclang* na hora de visitar o código
    - Declarações a serem ignoradas, que não devem ser incluídas no código
      *wrapper*
    - Declarações a serem renomeadas no código *wrapper*. Pode ser usado, por
      exemplo para remover prefixos usados como *namespace* em código C
    - Informação se *enum* deve ser colocado em um escopo (*namespace*)
      separado, ou não
    - Notas sobre argumentos de funções, pois código C pode ser um tanto quanto
      difícil de decifrar (qualquer ajuda é bem vinda ^^). Ver `Notas`_.

.. _Notas: notas.rst

.. _Visitor:

**Visitor (Visitante)**
    *Visitor* é uma entidade que visita o código C coletando as informações
    necessárias. Atualmente, são coletadas:

    - Declarações de *structs* e *unions*, com informações sobre seus campos
      (nome e tipo) se disponível
    - Declarações de *enums* e seus valores associados (nome e valor)
    - Declarações de funções, com informações sobre seus argumentos (tipos) e
      tipo de retorno

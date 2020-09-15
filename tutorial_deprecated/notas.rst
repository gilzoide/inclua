Notas sobre funções
===================
Muitas funções em C são difíceis de serem decifradas somente por seu protótipo.
Pointeiros como argumento, por exemplo, podem ser um argumento de entrada, um
argumento de saída (para múltiplos retornos, por exemplo), ou mesmo um vetor de
entrada, que deve ser levado em consideração na hora de gerar código *wrapper*.

Para facilitar a nossa vida, foram criadas **Notas**, que informam ``inclua``
o que cada argumento (ou mesmo o retorno) de uma função quer dizer. Nem todas
as linguagens alvo funcionam do mesmo jeito, mas se todas as possibilidades
forem cobertas, cada uma pode usar as informações do jeito que melhor couber.


Padrão
------
Sempre que funções forem anotadas, todos seus argumentos devem ser cobertos.
Isso significa que a lista de notas (tanto em Python_ quanto em YAML_) deve ter
tamanho de pelo menos o número de argumentos. Se houver mais uma anotação, ela
se refere ao valor de retorno da função.

.. _python: python_pt.rst
.. _yaml: yaml_pt.rst

Em **inclua** os argumentos das funções são sempre nomeados "argX", onde "X" é
substituído por seu índice começando em 1, de modo que o primeiro argumento de
uma função chame "arg1", o segundo chame "arg2", e assim por diante. Essa
informação é valiosa na hora de determinarmos vetores e seus tamanhos, dentre
outros. Além disso, retornos de funções são sempre chamados "ret".


Notas Para Funções
------------------
**ignore**
    Ignora a função, não criando *wrappers* para ela.

**native (função nativa)**
    Marca funções que já são *wrappers*, e portanto não precisam ser
    modificadas. Isso é importante, pois às vezes pode ser necessário criar
    funções customizadas para interagir bem com a linguagem alvo.


Notas Para Argumentos
---------------------
.. _in:

**in (entrada)**
    Uma entrada, como normalmente se esperaria. É possível definir um valor
    padrão para a entrada, e linguagens alvo podem usá-lo como valor padrão
    para a chamada da função (depende da linguagem).

    Exemplo:

    .. code:: c

        // Retorna a soma de dois inteiros
        // Notas:
        //   a - in
        //   b - in
        int soma (int a, int b);

        // Calcula a velocidade final de um queda livre no tempo `t`. Gravidade padrão da Terra
        // Notas:
        //   t - in
        //   h0 - in
        //   g - in = 9.81
        double velocidadeFinalQuedaLivre (double t, double h0, double g);

    Formato, em EBNF:

    .. code:: ebnf

        Input = 'in', [ [ espaço ], valor_padrão ]
        valor_padrão = '=', [ espaço ], tudo ;

.. _out:

**out (saída)**
    Argumento de saída, valores passados por referência que servem para retorno.
    Linguagens alvo que suportarem múltiplos retornos em funções podem adicionar
    esses valores aos retornos, fazendo com que não seja necessário ao usuário
    passar uma variável no parâmetro. É possível definir uma função para
    liberação de memória alocada pela função após definição do retorno,
    notavelmente para *strings*.

    Exemplo:

    .. code:: c

        // Retorna as coordenadas X e Y de um Ponto2D = struct { int x; int y; }
        // Notas:
        //   p - in
        //   x - out
        //   y - out
        void getXY (Ponto2D * p, int * x, int * y);

        // Gera uma string aleatória, que deve ser liberada usando a função `free` quando não mais for necessária
        // Notas:
        //   (retorno) - out free[free]
        char * randString ();

    Formato, em EBNF:

    .. code:: ebnf

         Output = 'out', [ espaço, libera ] ;
         libera = 'free[', identificador, ']' ;
         identificador = (letra | '_'), { (letra | numero | '_') } ;

.. _inout:

**inout (entrada e saída)**
    Há argumentos em funções em C que são passadas por referência e não só têm
    seu valor utilizado, como o modifica, e tal modificação é persistente. Para
    esses casos, há a **nota** **inout**, que é uma mistura da in_ e out_. Pode
    ser útil para linguagens alvo que não podem passar tipos nativos (inteiros
    e *floats*, por exemplo) por referência para funções.

    .. code:: c

        // Troca o valor de `a` com o de `b`
        // Notas:
        //   a - inout
        //   b - inout
        void troca (int * a, int * b);

    Formato, em EBNF:

    .. code:: ebnf

        InOut = 'inout', [ libera ], [ valor_padrão ];

.. _array in:

**array in (vetor de entrada)**
    Entrada que é um vetor. Muitas das vezes, um ponteiro como argumento, em C,
    se refere a um vetor. Muitas linguagens alvo possuem uma estrutura de dados
    análoga ao vetor de C, como listas, ou hash tables com índices numéricos.
    Essa informação é então importante para podermos usar as estruturas nativas
    das linguagens alvo e fazer a conversão automaticamente, ao invés de criar
    *wrappers* para vetores de C, que fica muito ruim de usar (*wrappers* devem
    ter usabilidade o mais parecido possível com código nativo, ou não serve).

    Funções que recebem vetores como entrada, em C, costumam vir acompanhadas
    pelo tamanho do vetor. Vetores podem ser multidimensionais, e toda e cada
    dimensão deve ter uma anotação entre colchetes "[]".

    Em muitas linguagens, as estruturas de listas já contêm informação sobre
    suas dimensões. Para argumentos que são vetores, o argumento com seu
    tamanho pode ser indicado pela nota `size in`_, e tirada automaticamente da
    estrutura de dados pelo *wrapper* gerado, tirando a necessidade do
    programador passar o argumento do tamanho na função. Há vezes, porém, que
    tal informação não é necessária. Nesse caso, ainda é necessário anotar que
    existe a dimensão, mas basta indicar que esta não importa usando o caractere
    "_".

    Exemplos:

    .. code:: c

        // Retorna a soma de todos os valores de um vetor de inteiros de tamanho `tamanho`
        // Notas:
        //   vetor - array[arg2] in
        //   tamanho - size in
        int somaVetor (int * vetor, size_t tamanho);

        // Retorna a soma de todos os valores de um vetor de inteiros, até encontrar um valor 0
        // Notas:
        //   vetor - array[_] in
        int somaVetorAteZero (int * vetor);

        // Calcula o determinante de uma matriz
        // Notas:
        //   matriz - array[arg2][arg2] in
        //   tamanho - size in
        double determinante (double ** matrix, size_t tamanho);


    Formato, em EBNF:

    .. code:: ebnf

        ArrayIn = 'array', Dimensão, { Dimensão }, espaço, 'in' ;
        Dimensão = '[' tudo_menos_colchete ']' ;

.. _size in:

**size in (tamanho de vetor de entrada)**
    Como dito anteriormente, vetores costumam vir acompanhadas de seus tamanhos.
    Existe então uma **nota** para argumentos que são o tamanho do vetor, pois
    em muitas linguagens alvo esse tamanho pode ser tirado da própria estrutura
    de lista, não precisando ser explicitamente passado como parâmetro para a
    função.

    Exemplo:

    .. code:: c

        // Imprime os números do vetor de tamanho `tamanho`
        // Notas:
        //   vetor - array[arg2] in
        //   tamanho - size in
        void imprimeNumeros (int * vetor, size_t tamanho);

    Formato, em EBNF:

    .. code:: ebnf

        SizeIn = 'size', [ ' in' ] ;

.. _array out:

**array out (vetor de saída)**
    Saída que é um vetor. Linguagens alvo devem alocar a memória necessária para
    o vetor dinamicamente e liberá-lo depois se necessário. O retorno de uma
    função também pode apresentar essa **nota**, nesse caso não alocando a
    memória.

    .. code:: c

        // Popula o vetor com números no intervalo [a, b). `vetor` deve ter
        // tamanho de pelo menos `b - a`
        // Notas:
        //   vetor - array[b - a] out
        //   a - in
        //   b - in
        void range (int * vetor, int a, int b);

        // Gera um vetor de tamanho `n` de inteiros aleatórios
        // Notas:
        //   tamanho - in
        //   (retorno) - array[arg1] out
        int * geraAleatorios (size_t n);

    Formato, em EBNF:

    .. code:: ebnf

        ArrayIn = 'array', Dimensão, { Dimensão }, espaço, 'out' ;
        Dimensão = '[' tudo_menos_colchete ']' ;

.. _size out:

**size out (tamanho de vetor de saída)**
    Às vezes, vetores de saída são criados pelas funções com tamanho
    arbitrário, sendo esse retornado de algum modo, normalmente por parâmetro.
    Essa **nota** é, assim, uma mistura da `size in`_ e `out`_.

    .. code:: c

        // Gera um vetor de tamanho aleatório (entre 1 e 10) de números aleatórios (entre 0 e 1)
        // Notas:
        //   tamanho - size out
        //   (retorno) - array[arg1] out
        float * geraAleatorios (size_t * tamanho);

    Formato, em EBNF:

    .. code:: ebnf

        SizeOut = 'size out' ;

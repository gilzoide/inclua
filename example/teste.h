#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#define ZERO 0

typedef int Inteiro;

float somaVet (float *vet, size_t tam) {
	int i;
	float soma = ZERO;
	for (i = 0; i < tam; i++) {
		soma += vet[i];
	}
	return soma;
}

typedef struct Oi {
	int a;
	int b;
} Oi;

union Outra {
	int i;
	char c;
	Oi o;
};

typedef enum nice {
	COMO_VAI,
	VOCES,
	VAI,
	GENTEM,
} Nice;

enum {
	TAO,
	TUDO,
	BAO,
	HEIN
};

struct ComEnumEAnon {
	Nice n;
	struct {
		int x;
		int y;
	} ponto;
};

Oi *getOi (Oi *o) {
	return o;
}

void getAB (Oi *o, int *a, int *b) {
	*a = o->a;
	*b = o->b;
}

float somaVetAte0 (float *vet) {
	float soma = 0;
	while (*vet) {
		soma += *vet;
		vet++;
	}
	return soma;
}

void range (int *vet, int inicio, int ate) {
	int i;
	for (i = inicio; i < ate; i++) {
		vet[i - inicio] = i;
	}
}

int *rangeAlloc (int inicio, int ate) {
	int *vet = (int *) malloc ((ate - inicio) * sizeof (int));
	range (vet, inicio, ate);
	return vet;
}

void oiMundo () {
	puts ("oie");
}

int getSoma (Oi *O) {
	return O->a + O->b;
}

void printaI (union Outra *o) {
	printf ("%d\n", o->i);
}

void printaMatriz (int **mat, int tam1, int tam2) {
	int i, j;
	for (i = 0; i < tam1; i++) {
		for (j = 0; j < tam2; j++) {
			printf ("%d ", mat[i][j]);
		}
		puts ("");
	}
}

void printaMatrizQuadrada (int **mat, int tam) {
	printaMatriz (mat, tam, tam);
}

int * geraAleatorios (size_t * tamanho) {
	size_t n = rand () % 9 + 1;
	int * vetor, i;
	if ((vetor = (int *) malloc (n * sizeof (int))) == NULL) {
		*tamanho = 0;
		return NULL;
	}
	*tamanho = n;

	for (i = 0; i < n; i++) {
		vetor[i] = rand ();
	}
	return vetor;
}

void swap (int * a, int * b) {
	int aux = *a;
	*a = *b;
	*b = aux;
}

// typedef int (*RetInt) ();
// void printaResult (RetInt f) {
void printaResult (int (*f) (int)) {
	if (f) {
		printf ("%d\n", f (1));
	}
	else {
		puts ("poxa, queria função =/");
	}
}

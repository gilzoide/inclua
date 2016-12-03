#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <stddef.h>

float somaVet (float *vet, size_t tam) {
	int i;
	float soma = 0;
	for (i = 0; i < tam; i++) {
		soma += vet[i];
	}
	return soma;
}

struct Oi {
	int a;
	int b;
};

union Outra {
	int i;
	char c;
	Oi o;
};

typedef enum {
	COMO_VAI,
	VOCES,
} Nice;

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

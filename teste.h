#include <stdio.h>

typedef struct Oi Oi;

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

float somaVet (float *vet, int tam) {
	int i;
	float soma = 0;
	for (i = 0; i < tam; i++) {
		soma += vet[i];
	}
	return soma;
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

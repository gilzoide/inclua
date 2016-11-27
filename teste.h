#include <stdio.h>

typedef struct Oi Oi;

struct Oi {
	int a;
	int b;
};

union Outra {
	int i;
	char c;
	// struct S {
		// int a;
		// int b;
	// } s;
};

typedef enum {
	COMO_VAI,
	VOCES,
} Nice;

Oi *getOi (Oi *o) {
	return o;
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

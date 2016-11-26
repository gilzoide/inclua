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

void oiMundo () {
	puts ("oie");
}

int getSoma (Oi *O) {
	return O->a + O->b;
}

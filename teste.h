#include <stdio.h>

typedef struct _Oi {
	int a;
	int b;
} Oi;

struct Outra {
	int o;
};

Oi *getOi (Oi *o) {
	return o;
}

void oiMundo () {
	puts ("oie");
}

int getSoma (Oi *O) {
	return O->a + O->b;
}

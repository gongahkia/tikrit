compiler := gcc -o src/a.out
spec := -lraylib -ldl -lpthread -lm -lX11

all: build run

build: src/main.c
	$(compiler) src/main.c $(spec)

run: src/a.out
	./src/a.out

clean:
	rm -f src/a.out

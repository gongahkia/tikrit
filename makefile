compiler := gcc -o src/a.out
spec := -lraylib -ldl -lpthread -lm -lX11

all: build run

build: src/main.c
	clear && $(compiler) src/main.c $(spec)

run: src/a.out
	clear && ./src/a.out

clean:
	clear && rm -f src/a.out

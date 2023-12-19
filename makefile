compiler := love

all: build

build: src
	clear && love src

clean:

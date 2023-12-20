compiler := love

all: build

build: src
	clear && love src

debug: src
	(time love src) 2>&1 | tee test/log.txt

clean:
	rm test/log.txt
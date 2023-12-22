compiler := love

all: build

build: src
	clear && love src

reset:
	cp map/1-fresh.txt map/1.txt && cp map/2-fresh.txt map/2.txt

debug: src
	(time love src) 2>&1 | tee test/log.txt

clean:
	rm test/log.txt
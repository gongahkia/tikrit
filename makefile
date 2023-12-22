compiler := love

all: build

build: src
	clear && love src

reset:
	cp map/map1-fresh.txt map/map1.txt && cp map/map2-fresh.txt map/map2.txt

debug: src
	(time love src) 2>&1 | tee test/log.txt

clean:
	rm test/log.txt
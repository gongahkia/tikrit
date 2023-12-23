compiler := love

all: build

build: src
	clear && love src

reset:
	cp map/1-fresh.txt map/1.txt && cp map/2-fresh.txt map/2.txt && cp map/3-fresh.txt map/3.txt && cp map/4-fresh.txt map/4.txt && cp map/5-fresh.txt map/5.txt && cp map/6-fresh.txt map/6.txt && cp map/7-fresh.txt map/7.txt && cp map/8-fresh.txt map/8.txt && cp map/9-fresh.txt map/9.txt && cp map/10-fresh.txt map/10.txt 

debug: src
	(time love src) 2>&1 | tee test/log.txt

clean:
	rm test/log.txt
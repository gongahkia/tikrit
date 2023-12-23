compiler := love

all: build

build: src
	clear && love src

reset:
	cp map/1-fresh.txt map/1.txt && cp map/2-fresh.txt map/2.txt && cp map/3-fresh.txt map/3.txt && cp map/4-fresh.txt map/4.txt && cp map/5-fresh.txt map/5.txt && cp map/6-fresh.txt map/6.txt && cp map/7-fresh.txt map/7.txt && cp map/8-fresh.txt map/8.txt && cp map/9-fresh.txt map/9.txt && cp map/10-fresh.txt map/10.txt && cp map/11-fresh.txt map/11.txt && cp map/12-fresh.txt map/12.txt && cp map/13-fresh.txt map/13.txt && cp map/14-fresh.txt map/14.txt && cp map/15-fresh.txt map/15.txt

debug: src
	(time love src) 2>&1 | tee test/log.txt

clean:
	rm test/log.txt
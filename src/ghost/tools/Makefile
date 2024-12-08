CC = $(CROSS_COMPILE)gcc
CFLAGS = -Wall -O2 -I../include
LDFLAGS = -L../src -lghostc -lm -lpthread

TARGETS = ghostc-neural ghostc-monitor

.PHONY: all clean install

all: $(TARGETS)

ghostc-neural: ghostc-neural.c
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS)

ghostc-monitor: ghostc-monitor.c
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS)

install:
	install -d $(DESTDIR)/usr/local/bin
	install -m 755 $(TARGETS) $(DESTDIR)/usr/local/bin/

clean:
	rm -f $(TARGETS) *.o

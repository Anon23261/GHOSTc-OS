CC = $(CROSS_COMPILE)gcc
CFLAGS = -Wall -O2 -I../include
LDFLAGS =

SOURCES = ghostc-core.c
OBJECTS = $(SOURCES:.c=.o)
TARGET = libghostc.so

.PHONY: all clean install

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) -shared -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -fPIC -c $< -o $@

install:
	install -d $(DESTDIR)/usr/local/lib
	install -m 755 $(TARGET) $(DESTDIR)/usr/local/lib/
	install -d $(DESTDIR)/usr/local/include/ghostc
	install -m 644 ../include/ghostc/*.h $(DESTDIR)/usr/local/include/ghostc/

clean:
	rm -f $(OBJECTS) $(TARGET)

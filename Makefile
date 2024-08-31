#### variables section
# change them if needed

# xpaint version
VERSION = 0.2.0

# instalation path
PREFIX = /usr/local
MANPREFIX = $(PREFIX)/share/man

# tools
CC ?= clang
CLANGTIDY ?= clang-tidy
CTAGS ?= ctags

#### targets section

libs = lib/incbin.h lib/stb_ds.h lib/stb_image.h lib/stb_image_write.h
headers = config.h types.h
src = xpaint.c
debs = tags $(libs) $(headers) $(src) res/

all: help ## default target

help: ## display this help
	@echo 'Usage: make [TARGET]... [ARGS="..."]'
	@echo ''
	@echo 'targets:'
	@sed -ne '/@sed/!s/:.*##//p' $(MAKEFILE_LIST) | column -tl 2

run: xpaint-d ## run application with ARGS
	./xpaint-d -v $(ARGS)

xpaint: $(debs) ## build release application
	@$(CC) -o $@ $(src) $(CCFLAGS) -O2 -DNDEBUG

xpaint-d: $(debs) ## build debug application
	@$(CC) -o $@ $(src) $(CCFLAGS) -g

clean: ## remove generated files
	@rm -f xpaint xpaint-d

install: xpaint ## install application
	@mkdir -p $(PREFIX)/bin
	cp -f xpaint $(PREFIX)/bin
	@chmod 755 $(PREFIX)/bin/xpaint
	@mkdir -p $(MANPREFIX)/man1
	sed "s/VERSION/$(VERSION)/g" < xpaint.1 > $(MANPREFIX)/man1/xpaint.1
	@chmod 644 $(MANPREFIX)/man1/xpaint.1

uninstall: ## uninstall application
	rm -f $(PREFIX)/bin/xpaint
	rm -f $(MANPREFIX)/man1/xpaint.1

check: ## check code with clang-tidy
	$(CLANGTIDY) $(src)

dev: clean ## generate dev files
	bear -- make xpaint-d

tags: $(libs) $(headers) $(src)
	@$(CTAGS) $^

.PHONY: all help run clean install uninstall check dev

#### compiler and linker flags

INCS = -I/usr/X11R6/include -I/usr/include/freetype2
LIBS = -L/usr/X11R6/lib -lX11 -lX11 -lm -lXext -lXft -lXrender
DEFINES = -DVERSION=\"$(VERSION)\" \
	$(shell \
		for res in ./res/* ; do \
			echo -n $$(basename $$res) \
				| tr '-' '_' \
				| sed -En 's/(.*)\..*/\U-DRES_SZ_\1/p'; \
			echo -n "=$$(stat -c %s $$res) "; \
		done \
	)
CCFLAGS = -std=c99 -pedantic -Wall $(INCS) $(LIBS) $(DEFINES)

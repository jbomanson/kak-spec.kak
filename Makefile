PREFIX     ?= /usr/local
BUILD      ?= build
BIN_SOURCE := $(wildcard bin/*)

all:
	true

doc: lib/reporter
	yard doc $<

README.md: README.md.erb bin/kak-spec rc/spec.kak
	erb -T- $< >$@


#       Build Man Pages


MAN_SOURCE	:= $(wildcard man/*.1.md.erb)
MAN_BUILD	:= $(patsubst man/%.1.md.erb,$(BUILD)/share/man/man1/%.1.gz,$(MAN_SOURCE))

build_man: $(MAN_BUILD)

$(BUILD)/share/man/man1/%.1.gz: man/%.1.md.erb
	@mkdir -p $(@D)
	erb -T- $< | pandoc --standalone --to man | gzip >$@


#       Install everything


install: install_bin install_man

install_bin: $(BIN_SOURCE)
	install -d $(DESTDIR)$(PREFIX)/bin/
	ln -f -s -t $(DESTDIR)$(PREFIX)/bin $(abspath $+)

install_man: $(MAN_BUILD)
	install -d $(DESTDIR)$(PREFIX)/share/man/man1/
	ln -f -s -t $(DESTDIR)$(PREFIX)/share/man/man1 $(abspath $+)

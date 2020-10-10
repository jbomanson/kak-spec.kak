PREFIX		?= /usr/local
BIN_SOURCE	:= $(wildcard bin/*)
MAN_SOURCE	:= $(wildcard man/*.1.md.erb)
MAN_OUTPUT	:= $(patsubst man/%.1.md.erb,share/man/man1/%.1,$(MAN_SOURCE))
README_DEPENDENCIES	:= lib/runner.sh rc/kak-spec.kak-spec

all:
	true

doc: lib/reporter.rb preprocess
	yard doc $<

# This target represents files that should be checked in the repository.
preprocess: README.md $(MAN_OUTPUT)

#
#       Preprocess Documentation
#

README.md: README.md.erb $(README_DEPENDENCIES)
	erb -T- $< >$@

#
#       Preprocess Man Pages
#

preprocess_man: $(MAN_OUTPUT)

share/man/man1/%.1: man/%.1.md.erb $(README_DEPENDENCIES)
	@mkdir -p $(@D)
	erb -T- $< | pandoc --standalone --to man >$@

#
#       Install everything
#

install: install_bin install_man

install_bin: $(BIN_SOURCE)
	install -d $(DESTDIR)$(PREFIX)/bin/
	ln -f -s -t $(DESTDIR)$(PREFIX)/bin $(abspath $+)
	install -d $(DESTDIR)$(PREFIX)/share
	ln -f -s -t $(DESTDIR)$(PREFIX)/share $(PWD)

install_man: $(MAN_OUTPUT)
	install -d $(DESTDIR)$(PREFIX)/share/man/man1/
	ln -f -s -t $(DESTDIR)$(PREFIX)/share/man/man1 $(abspath $+)

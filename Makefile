# This makefile supports markdown processing; it's intended for use
# when disconnected from the Internet.
# It uses pattern rules, which aren't in the POSIX standard
# (though they are proposed). For now, GNU Make works, as do many other
# make systems in practice.

# The program for processing markdown; takes filename, generates to stdout.
MARKDOWN=markdown2.py

%.html : %.md
	$(MARKDOWN) $< > $@

HTML_FILES = criteria.html background.html

all: $(HTML_FILES)


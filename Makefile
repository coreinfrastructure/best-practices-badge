# This makefile supports markdown processing; it's intended for use
# when disconnected from the Internet.
# It uses pattern rules, which aren't in the POSIX standard
# (though they are proposed). For now, GNU Make works, as do many other
# make systems in practice.

# A program for processing markdown; takes a filename, generates to stdout.
MARKDOWNFLAGS=-x link-patterns --link-patterns-file markdown-urls \
              -x smarty-pants -x code-friendly
MARKDOWN=markdown2.py $(MARKDOWNFLAGS)

%.html : %.md
	$(MARKDOWN) $< > $@

HTML_FILES = criteria.html background.html implementation.html other.html

all: $(HTML_FILES)


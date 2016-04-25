# This Makefile regenerates 'favicon.ico' and re-installs it.

# On Ubuntu you can install icotool with:
#   sudo apt-get install icoutils
#
# %.transparent.png: %.png.png
#	pngtopnm $< | pnmtopng -transparent =white > $@
#

FAVICON_SRC = favicon2x.png.png favicon.png.png

favicon.ico: $(FAVICON_SRC)
	icotool -c $(FAVICON_SRC) > favicon.ico
	cp -p favicon.ico ../app/assets/images/

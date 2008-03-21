The Makefile should make it easy to install the tools on Unix-like systems.

Install with
	make install

Uninstall with
	make uninstall

Build documentation (pre-built documentation is distributed in the
distribution ZIP file) if you need to with:
	make doc

Set PREFIX (distributed as /usr/local) to the base directory where you want
to do the installation. Installs in $(PREFIX)/bin and ($PREFIX)/lib/perl.

Either edit PREFIX or use
	make PREFIX=/my/install/directory ...
to install somewhere else.

If you don't have the perl library path in your perl
includes, you'll need to add that directory to the PERLLIB
environment variable.

There's no installation script for Windows. It would probably also
need a bunch of little BAT files to run the BWFW scripts.

All Installations
=================

Several of the scripts also need Eric Fry's Wiz Firmware Tools Package
installed and in your PATH variable. Source code of Wiz Firmware Tools
is available from the OpenWiz repository.

Executables of Eric's tools wiz_unpack, wiz_pack and wiz_genromfs
compiled for Windows and Cygwin are included with the ZIP distribution
of BWFWTools available from http://www.beyonwizsoftware.net/.
The Cygwin cygwin1.dll that is needed for these executables to run
on Windows is also included with that distribution.
If you have Windows, but don't use Cygwin, this is the easiest way to
ensure that you have all the components needed to run BWFWTools.


Linux, Mac OSX, Cygwin & other Unix or Unix-like environments
=============================================================

BWFWTools is written in the scripting language Perl (http://www.perl.org/).
Perl is almost always part of the installation environment in
Unix-like environments. If it's not installed on a Linux system,
use the appropriate package manager to install it. On Cygwin, use
the Cygwin Setup installer and make sure "Interpreters, Perl" is
set for installation.

The Makefile should make it easy to install the tools on Unix-like
systems.

Install with
	make install

The PREFIX variable in the Makefile determines where the
installed files will go.
Set PREFIX (distributed as /usr/local) to the base directory where
you want to do the installation. Installs in $(PREFIX)/bin and
($PREFIX)/lib/perl.

Either edit PREFIX in the Makefile or use
	make PREFIX=/my/install/directory ...
to install somewhere else.

On Cygwin, if you want to use the included pre-compiled executables from
Eric Fry's Wiz Firmware tools, install using:
	make cygwin_install

Uninstall with
	make uninstall
or
	make cygwin_uninstall
as appropriate.

Use the same PREFIX for the uninstall as you used for install.

Build the documentation (pre-built documentation is distributed in
the distribution ZIP file) if you need to with:
	make doc

HTML documentation will be placed in the html subdirectory of the
distribution. An index to the HTML documentation is placed in
html/index.html. Plain text documentation will be placed in the doc
directory.

If you don't have the Perl library path in your Perl includes,
you'll need to add that directory to the PERLLIB environment variable.
You'll also need to put $(PREFIX)/bin in your PATH variable.

If, when you run any of the BWFWTools, you get an error like:

	Can't locate IO/Uncompress/Gunzip.pm in @INC...

you'll need to install some Perl modules. The CPAN library allows
you to download and install packages easily. CPAN uses the Perl
programming convention for naming modules. In the module name (such
as IO/Uncompress/Gunzip.pm) change all of the '/'s to '::' and drop
the '.pm'. So to download the package that's missing in  that error
message, just run:

	cpan IO::Uncompress::Gunzip


Windows
=======

BWFWTools is written in the scripting language Perl (http://www.perl.org/).
Perl is not part of the Windows standard installation. BWFWTools
is known to work with the free version of ActivePerl
(http://www.activestate.com/).  Use version 5.10.0.1003 or more
recent.

There's no installation script for BWFWTools for Windows.

The simplest installation is to unpack BWFWTools into a suitable
location (say, in C:\Program Files) and add its directory
(C:\Program Files\BWFWTools if you've installed there) to your PATH
environment variable.

You'll also need to add the directory to your PERLLIB environment
variable, or create a new PERLLIB variable if there isn't one
already.

If, when you run any of the BWFWTools, you get an error like:

	Can't locate IO/Uncompress/Gunzip.pm in @INC...

you'll need to install some Perl modules. If you're using ActivePerl,
use the ActivePerl PPM library to get the module. PPM uses the Perl
form for naming modules. In the module name (such as
IO/Uncompress/Gunzip.pm) change all of the '/'s to '::' and drop
the '.pm'. So to download the package that's missing in  that error
message, just run:

	ppm IO::Uncompress::Gunzip

This particular module is part of the ActivePerl 5.10.0.1003
distribution, but you may need to apply the same procedure for other
Perl modules if they are missing.

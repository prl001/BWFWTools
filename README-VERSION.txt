Version 0.2

Contents of the zip:

    * Makefile - Unix make file for install/uninstall/build documentation
    * README.txt - some useful information about installing BWFWTools on Unix-like systems
    * bw_rootfs - extract or update the root filesystem romfs image in an uncompressed Beyonwiz kernel
    * bwhack - remotely enable and disable Beyonwiz "hacks"
    * getksyms - extract the kernel module symbol table from an uncompressed Beyonwiz kernel
    * gunzip_bflt - convert gzip-compressed bFLT executable files into uncompressed bFLT
    * make_kernel_bflt - convert a Beyonwiz kernel image into a bFLT executable
    * pack_wrp - pack a Beyonwiz firmware update file
    * unpack_wrp - unpack a Beyonwiz firmware update file
    * bw_patcher - all-in-one tool to automatically apply Beyonwiz firmware patches
    * wrp_hdrs - print the header information in Beyonwiz .wrp firmware update files
    * svcdat - print the contents of Beyonwiz C<svc.dat> (service scan configuration) files
    * Beyonwiz::Kernel - Perl package of support routines for uncompressed Beyonwiz kernel images
    * Beyonwiz::Hack - contains patcher modules to use with bw_patcher
    * Beyonwiz::Hack::BackgroundChanger - change the background image used in the File Player and Setup screens
    * Beyonwiz::Hack::BwhackSupport - Support for hacks that can be turned on and off remotely using bwhack
    * Beyonwiz::Hack::PutFile - Put a single file into an existing directory in the firmware
    * Beyonwiz::Hack::RemFile - Remove a file from the firmware
    * Beyonwiz::Hack::Telnet - Enable the telnet daemon in the firmware (allows remote logins to the Beyonwiz using telnet)
    * Beyonwiz::Hack::USBHackSupport - Allows hacks to be run from a USB stick or memory card
    * make_doc.sh - Unix shell script to generate HTML and text documentation from embedded POD markup
    * doc\ - Automatically generated documentation in plain text
    * html\ - Automatically generated documentation in html (index in index.html)
    * etc\ - Beyonwiz firmware patches that can be used in conjunction with Beyonwiz::Hack::USBHackSupport and Beyonwiz::Hack::BwhackSupport


Only extensively tested on Cygwin. Some testing on Mac OS X & Windows. Will probably work on Linux and other Unix variants.

WARNING: bw_rootfs, pack_wrp and bw_patcher can all easily create an unbootable system.

Release notes
bw_patcher: new tool
svcdat: new tool
getksyms: fails gracefully on firmware versions 01.05.269 beta and later, which don't have a kernel symbol table for module loading.
wrp_headers: Print out system ids in the same way that they appear on the Beyonwiz.
bw_rootfs: prints more information about free space in the firmware, updating code a bit more robust

In several tools, the way that sub-tools are called has been changed to avoid possible problems with shell quoting, and a bug in Cygwin Perl 5.10.0 IO::Uncompress::Gunzip::gunzip() has bee worked around.

WARNING
=======

*****************************************************************
Using user extensions or hacks may make your Beyonwiz unable to
operate correctly, or even start. Some modifications are known to
interfere with the correct functioning of the Beyonwiz.
*****************************************************************

If your Beyonwiz cannot start after you load modified firmware, you
may need to use the procedures in the "NOTICE - How to recover from
FW update failure" (http://www.beyonwiz.com.au/phpbb2/viewtopic.php?t=1298)
procedure on the Beyonwiz forum.  It's not known whether that
procedure will fix all failures due to user modifications or "hacks".

If you run modified firmware on your Beyonwiz, and have problems
with its operation, try to reproduce any problems you do have on a
Beyonwiz running unmodified firmware, or at least mention the
modifications you use when reporting the problem to Beyonwiz support
or on the Beyonwiz Forum (http://www.beyonwiz.com.au/phpbb2/index.php).
Beyonwiz support may not be able to assist if you are running
anything other than unmodified firmware from Beyonwiz.  Forum
contributers may be able to be more flexible, but they will need
to know what modifications you have made.

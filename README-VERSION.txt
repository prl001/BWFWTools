Version 0.2.3

Contents of the zip:

    * Makefile - Unix make file for install/uninstall/build documentation
    * README.txt - some useful information about installing BWFWTools on Unix-like systems
    * README-VERSION.txt - Release notes for the version
    * bw_rootfs - extract or update the root filesystem romfs image in an uncompressed Beyonwiz kernel
    * bwhack - remotely enable and disable Beyonwiz "hacks"
    * getksyms - extract the kernel module symbol table from an uncompressed Beyonwiz kernel
    * gunzip_bflt - convert gzip-compressed bFLT executable files into uncompressed bFLT
    * make_kernel_bflt - convert a Beyonwiz kernel image into a bFLT executable
    * pack_wrp - pack a Beyonwiz firmware update file
    * print_flash - extract the memory file device data from an uncompressed Beyonwiz kernel
    * unpack_wrp - unpack a Beyonwiz firmware update file
    * bw_patcher - all-in-one tool to automatically apply Beyonwiz firmware patches
    * wrp_hdrs - print the header information in Beyonwiz .wrp firmware update files
    * svcdat - print the contents of Beyonwiz C<svc.dat> (service scan configuration) files
    * dump_strings - extract useful GUI strings from Beyonwiz /dump.dat file
    * lastplaypoint - print the Beyonwiz resume marker file lastplaypoint.dat
    * getDvpStrings - extract useful GUI strings from the Beyonwiz wizdvp application
    * Beyonwiz::Kernel - Perl package of support routines for uncompressed Beyonwiz kernel images
    * Beyonwiz::Hack - contains patcher modules to use with bw_patcher
    * Beyonwiz::Hack::BackgroundChanger - change the background image used in the File Player and Setup screens
    * Beyonwiz::Hack::BwhackSupport - Support for hacks that can be turned on and off remotely using bwhack
    * Beyonwiz::Hack::Dim - hack to dim the front display
    * Beyonwiz::Hack::PutFile - Put a single file into an existing directory in the firmware
    * Beyonwiz::Hack::RemFile - Remove a file from the firmware
    * Beyonwiz::Hack::Telnet - Enable the telnet daemon in the firmware (allows remote logins to the Beyonwiz using telnet)
    * Beyonwiz::Hack::USBHackSupport - Allows hacks to be run from a USB stick or memory card
    * Beyonwiz::Hack::USBHackSupport - Allows hacks to be run from a USB stick or memory card
    * Beyonwiz::SystemId - Perl package of usefunctions for Beyonwiz SystemIds and model names
    * make_doc.sh - Unix shell script to generate HTML and text documentation from embedded POD markup
    * doc\ - Automatically generated documentation in plain text
    * html\ - Automatically generated documentation in html (index in index.html)
    * etc\ - Beyonwiz firmware patches that can be used in conjunction with Beyonwiz::Hack::USBHackSupport and Beyonwiz::Hack::BwhackSupport


Should work on Windows (user needs to have Perl installed), Cygwin under Windows, OS X and Linux.

WARNING: bw_rootfs, pack_wrp and bw_patcher can all easily create an unbootable system. bw_rootfs, pack_wrp and bw_patcher are untested on FV-L1 PVRs.

Release notes

dump_strings.pl: Add options to sort the output.
pack_wrp.pl: Suppress warnings about Windows style path separators coming from the new cygwin1.dll. Fixed recognition of default system type with longer name for DP-Lite.
unpack_wrp.pl: Suppress warnings about Windows style path separators coming from the new cygwin1.dll
bw_patcher.pl: Suppress warnings about Windows style path separators coming from the new cygwin1.dll
svcdat.pl: Attempt to improve operation after the firmware changes for Dynamic Channel Management.
Makefile: add installation of print_flash.
print_flash.pl: New tool. Extracts the memory file device data from an uncompressed Beyonwiz kernel
Beyonwiz::Kernel: Added kernel location information for versions 01.07.036+.
Beyonwiz::SystemId: Added system ids for DP-Lite.

Bugs:
pack_wrp cannot delete one of its temporary files on Windows sometimes. A warning is pinted, and the file can be deleted manually.
The decoding of the T1 and T2 fields in svcdat seems to be incorrect, and a correct decoding doesn't appear to be obvious.

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

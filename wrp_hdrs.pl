#!/usr/bin/perl

=pod

=head1 NAME

wrp_hdrs - print the header information in Beyonwiz .wrp firmware update files


=head1 SYNOPSIS

    wrp_hdrs firmware_files...

=head1 DESCRIPTION

Prints the header information in Beyonwiz .wrp firmware update files.

=head1 ARGUMENTS

Prints the contents of the header block in Beyonwiz B<.wrp>
firmware update files.

    ./wrp_hdrs.pl DPS1_Firmware_28Dec2007_ver_01.05.197.wrp 
    DPS1_Firmware_28Dec2007_ver_01.05.197.wrp:
	fileSize: 7768064
	  offset: 0
	   magic: WizFwPkgl
       machMagic: [0x0e20be3e, 0x08080000]
	 version: 01.05.197__Official.Version__
	 md5file: [cb, 92, 7d, 43, fa, 16, 48, 59, 08, 35, ef, 97, 9d, 44, 9e, fd]
	   count: 1
	imageTag: [108, 32]
       imageType: 2
     imageOffset: 512
     imageLength: 7767040
	md5image: [24, 81, 0c, f0, 35, 53, ce, 2a, 56, 17, 8d, b4, 45, 90, 2c, 67]
	  fsType: -rom1fs-
	  fsSize: 7766032
	   fsVol: mambo

=over 4

The example is for firmware release 1.05.197.

The output fields are:

=item fileSize

Size of the .wrp file.

=item offset

Offset of the start of the header in the file.

=item magic

The magic string that indicates that the file is a Beyonwiz firmware update.
Should always be C<WizFwPkgl>.

=item machMagic

The magic number that corresponds to the Beyonwiz System ID for the device.
Used to ensure that the firmware is for the correct type of device.

=item version

The version string that is printed in the verification popup window on the
beyonwiz when the firmware is uploaded for verification.

=item md5file

Checksum over the file, with this field set to zeros.

=item count

Count of the remaining payloads to process.
This interpretation is uncertain.
The value has only ever been observed to be 1.

=item imageTag

Uncertain interpretation.
Has always been observed to be [108, 32].

=item imageType

Type of firmware payload.

  0 - None
  1 - Boot loader
  2 - ROMFS
  3 - Splash Screen
  4 - Release Note

Has only been observed to have value 2.

=item imageOffset

Offset of the start of the payload for this header.

=item imageLength

Length of the payload.
The actual file alloction for the
payload appears to be rounded up to an even multiple of 1024 bytes,
as I<floor>((imageLength + 1023) / 1024 ) * 1024.
A zero-filled header block follows this allocated space as an empty header
to indicate the end of the package.

=item md5image

MD5 checksum of the payload (over exactly the given length).

=item fsType

Payload file system type.
Only B<-rom1fs-> for a Linux ROMFS file system has been observed.

=item fsSize

File system size.
For ROMFS file systems always an integer multiple of 16.

=item fsVol

File system volume label.

=back

=head1 BUGS

The interpretation of some parts of the header is uncertain.

The roundup for the allocation of the payload is uncertain.

=head1 ACKNOWLEDGEMENTS

Most of the header interpretation was done by efry (Eric)
on the Australian 
Beyonwiz Forum (L<http://www.beyonwiz.com.au/phpbb2/index.php>).

=cut

use strict;
use warnings;

# Read and unpack the .wrp file header from the current
# file handle read location
# Return a hash of its interpreted values, or undef on failure.

sub readHdrFilehandle($$) {
    my ($hdr, $off) = @_;
    $hdr->{fileSize} = (stat WRP)[7];
    $hdr->{offset} = $off;
    my $buf;

    sysread $hdr->{fileHandle}, $buf, 1024, $off or return undef;
    (
        $hdr->{magic},
	@{$hdr->{machMagic}}[0..3],
	$hdr->{version},
	@{$hdr->{md5file}}[0..15],
	$hdr->{count},
	@{$hdr->{imageTag}}[0..1],
	$hdr->{imageType},
	$hdr->{imageOffset},
	$hdr->{imageLength},
	@{$hdr->{md5image}}[0..15],
	$hdr->{fsType},
	$hdr->{fsSize},
	$hdr->{fsVol},
    ) = unpack 'Z12 v4 Z64 C16 V6 C16 @512 Z8 N x4 Z16', $buf;

    @{$hdr->{machMagic}}= reverse @{$hdr->{machMagic}};
    return $hdr;
}

# Open the file, and read and intepret the .wrp header.
# Return a hash of its interpreted values, or undef on failure.

sub readHdrFile($) {
    my ($fn) = @_;
    my $hdr = {};
    open WRP, $fn or return undef;

    $hdr->{fileHandle} = \*WRP;
    return readHdrFilehandle($hdr, 0);
}

# Formats for printing various fields in the header

my %formats = (
    machMagic => "%04x",
    md5file => "%02x",
    md5image => "%02x",
);

# Print the contents of the header $hdr on standard output

sub printHdr($) {
    my ($hdr) = @_;

    foreach my $fld (qw/fileSize offset magic machMagic version
		    md5file
		    count imageTag imageType imageOffset
		    imageLength spaceRemaining
		    md5image
		    fsType fsSize fsVol/) {
	my $fmt = $formats{$fld};
	$fmt = "%s" if(!defined($fmt));
	if(ref($hdr->{$fld}) eq 'ARRAY') {
	    printf "%14s: [%s]\n", $fld,
		join(', ', map {sprintf $fmt, $_} @{$hdr->{$fld}});
	} else {
	    printf "%14s: $fmt\n", $fld, $hdr->{$fld};
	}
    }
    print "Trailer padding not 512 bytes\n"
	if($hdr->{fileSize} - $hdr->{imageLength} - $hdr->{imageOffset}
	   != 512);
    print "File system padding not rounded up",
	    " to correct 1024-byte boundary\n"
	if(int(($hdr->{fsSize} + 1023)/1024) * 1024 != $hdr->{imageLength})
}

# Loop through the arguments, printing the headers.

foreach my $fn (@ARGV) {
    my $hdr = readHdrFile($fn);
    $hdr->{spaceRemaining} = 0x7b0000 - $hdr->{imageLength};
    if($hdr) {
	print "$fn:\n";
	printHdr($hdr);
    } else {
	warn "$fn: $!\n";
    }
}

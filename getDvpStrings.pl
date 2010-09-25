#!/usr/bin/perl

=pod

=head1 NAME

getDvpStrings - extract useful GUI strings from the Beyonwiz wizdvp application

=head1 SYNOPSIS

    getDvpStrings directory_containing_beyonwiz_application_firmware

=head1 DESCRIPTION

Edits the strings extracted from the Beyonwiz C<getDvpStrings>
application, eliminating strings that probably aren't GUI messages.

The directory argument is the root directory of an unpacked Beyonwiz
firmware .wrp file.

The intended use is:

    getDvpStrings 01.05.123.unpacked | dump_strings

=head1 PREREQUISITES

The Unix B<strings> program, and the
L< C<gunzip_bflt>|gunzip_bflt/>
program in B<BWFWTools>.

=head1 BUGS

The filtering is imperfect, and some strings may be included that should
be excluded, and some excluded that should be included.

=cut

use strict;
use warnings;

sub usage() {
    die "Usage: $0 BWAppDir\n"
}

@ARGV == 1 || usage;

my $bwDir = $ARGV[0];

my $wizDvpZip = $bwDir . '/001x_wizdvp/001x_wizdvp';
$wizDvpZip = $bwDir . '/wizdvp/wizdvp' if(!-f $wizDvpZip);

my $wizDvp = $wizDvpZip . '.unz';

!system "gunzip_bflt.pl \"$wizDvpZip\""
    or die "Can't unzip $wizDvpZip\n";

open STR, '-|', "strings \"$wizDvp\""
    or die "Can't extract strings from $wizDvp\n";

while($_ = <STR>) {
    chomp;
    if((/^Usage : %s \[options\]/../^EPGDB/)
    && /^[A-Z].* / && !/^[A-Z][A-Z0-9_]+[ \[]/
    && !/^(SIMPLEMM|POOLMM|POOLMM|LINKEDLISTMM|WIZMM|DCC|MRUA|TTONE)/
    && !/^(RAP|Parse[A-Z]|PANIC|SIOCS|ESSID|RTS |GFXLIB)/
    && !/RMGenericPropertyID/) {
	print $_, "\n";
    }
}

#!/usr/bin/perl

=pod

=head1 NAME

dump_strings - extract useful GUI strings from Beyonwiz /dump.dat file

=head1 SYNOPSIS

    dump_strings [extracted_GUI_strings_files...]

=head1 DESCRIPTION

Edits the strings extracted from the Beyonwiz C</dump.dat>
file, eliminating strings that probably aren't GUI messages,
and compacting the output by removing repeated strings and strings
that are substrings of other strings.

Where there are multiple copies of a string the string is tagged with C<(*)>
in the output.

The intended use is:

    strings dump.dat | dump_strings

=head1 PREREQUISITES

A tool like the Unix B<strings> program that can extract
printable strings from a binary file.

=head1 BUGS

The filtering is imperfect, and some strings may be included that should
be excluded, and some excluded that should be included.

=cut

use strict;
use warnings;

my $last = '';
my %rep;
my @strs;
my $reptag = '    (*)';
my %frags;

use constant FRAGLEN => 10;

use strict;

while(<>) {
    chomp;
    s/\s+$//;

    next if(!/ /
	 || /[<>]|^[ 	]|WXYZ|ABCD|\$\$|\[  \]|^1 =/
         || $_ ne $last && $_ eq substr($last, 0, length $_));

    my $fragIndex = substr $_, 0, FRAGLEN;
    $frags{$fragIndex}->{$_} = 1;
    $rep{$_}++;

    $last = $_;

    push @strs, $_ if($rep{$_} == 1);
}

foreach my $str (@strs) {
    if($rep{$str}) {
	my $fragIndex = substr $str, 0, FRAGLEN;
	my $isFragment;
	foreach my $fragstr (keys %{$frags{$fragIndex}}) {
	    if($str ne $fragstr
	    && $str eq substr $fragstr, 0, length($str)) {
		$rep{$str} = 0;
		$isFragment = 1;
		last;
	    }
	}
	if(!$isFragment) {
	    print $str;
	    print $reptag if($rep{$str} > 1);
	    print "\n";
	    $rep{$str} = 0;
	}
    }
}

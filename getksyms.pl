#!/usr/bin/perl

=pod

=head1 NAME

getksyms - extract the kernel module symbol table from an uncompressed Beyonwiz kernel


=head1 SYNOPSIS

    getksyms [-n|--numeric] beyonwiz_uncompressed_kernel

=head1 DESCRIPTION

Extract the kernel module symbol table from an uncompressed Beyonwiz kernel.

The Beyonwiz kernel contains a symbol table for all the functions and data
in the kernel module interface (used, for example, for runtime loadable
device drivers). This tool extracts and prints the symbol table
from a gunzipped Beyonwiz kernel image.

The symbols are flagged by B<t>, B<d> and B<b> for the
text (executable code), initialised data and bss (unitialised data)
segments respectively.

=head1 ARGUMENTS

The default is to print the symbols sorted by name.
The B<-n> (or B<--numeric>) sorts by symbol value.

=head1 PREREQUSITES

Uses packages C<Getopt::Long>
and L<C<Beyonwiz::Kernel>|Beyonwiz::Kernel>.

=head1 BUGS

Tries to use some contextual information to ensure that
the correct values for the location of the symbol table
and the segment boundaries have been found. These heuristics may fail
and the program may produce garbage.

=cut

use strict;
use warnings;

use Beyonwiz::Kernel
	qw(BASE check_magics check_sym get_words get_words_sym get_str);

# Extract the symbols published by the kernel for the module interface.

sub usage() {
    die "Usage: $0 [-n] beyonwiz_uncompressed_kernel\n";
}

use Getopt::Long;

Getopt::Long::Configure qw/no_ignore_case bundling/;

# Return B<t>, B<d> and B<b> if $addr is in the text (executable code),
# initialised data and bss (unitialised data) segments respectively.

sub where_sym($$$) {
    my ($addr, $etext, $bss) = @_;
    return 't' if($addr < $etext);
    return 'd' if($addr < $bss);
    return 'b';
}

my $nflag;

GetOptions('n|numeric' => \$nflag) or usage;

@ARGV == 1 or usage;

my $kern_fn = $ARGV[0];

open KERN, '<', $kern_fn or die "$0: $kern_fn - $!\n";

# Check that the kernel symbols are OK

check_magics($kern_fn, \*KERN);

die "$0: $kern_fn does not appear to have a kernel symbols table\n"
    unless(check_sym('__start___ksymtab') && check_sym('__stop___ksymtab'));

# Extract the symbol table pointers, and the locations of the segment
# boundaries

my $ksym_start	= get_words_sym(\*KERN, '__start___ksymtab', 1);
my $ksym_end	= get_words_sym(\*KERN, '__stop___ksymtab', 1);
my $etext	= get_words_sym(\*KERN, '_etext', 1);
my $bss		= get_words_sym(\*KERN, '__bss_start', 1);

my @symtab;

# Print the symbol table locations and the number of symbols

printf "Kernel symbol table: 0x%08x - 0x%08x (%d entries)\n",
	$ksym_start, $ksym_end, ($ksym_end-$ksym_start)/8;

# Extract the symbol table

for(my $sym = $ksym_start; $sym < $ksym_end; $sym += 8) {
    my ($addr, $nameaddr) = get_words(\*KERN, $sym, 2);
    my $name = get_str(\*KERN, $nameaddr);
    push @symtab, {
			addr => $addr,
			type => where_sym($addr, $etext, $bss),
			name => $name
		    };
}

# Print the sorted symbol table

my $sortfn = sub { $main::a->{name} cmp $main::b->{name} };
$sortfn = sub { $main::a->{addr} <=> $main::b->{addr} } if($nflag);

foreach my $sym (sort $sortfn @symtab) {
    printf "0x%08x %s %s\n", $sym->{addr}, $sym->{type}, $sym->{name};
}

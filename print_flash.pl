#!/usr/bin/perl

=pod

=head1 NAME

print_flash - extract the memory file device data from an uncompressed Beyonwiz kernel


=head1 SYNOPSIS

    print_flash beyonwiz_uncompressed_kernel

=head1 DESCRIPTION

Extract the memory file device data from an uncompressed Beyonwiz kernel.

The memory device arena containing the location of complete memory devices
and the MTD (Memory Technology Device) table, which contains the partitions of
the Beyonwiz flash memory are decoded and printed.

Sizes with the notation C<From ROMFS> indicate that the size of the device
is taken from the header of the ROMFS file system that the device contains.

Useful for checking the size of the flash memory device in a Beyonwiz
(or at least the size the kernel expects it to be).

=head1 ARGUMENTS

The only argument is the name of an uncompressed Beyonwiz kernal.

=head1 PREREQUSITES

Uses package L<C<Beyonwiz::Kernel>|Beyonwiz::Kernel>.

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
    die "Usage: $0 beyonwiz_uncompressed_kernel\n";
}

@ARGV == 1 or usage;

my $kern_fn = $ARGV[0];

open KERN, '<', $kern_fn or die "$0: $kern_fn - $!\n";

# Check that the kernel symbols are OK

check_magics($kern_fn, \*KERN);

die "$0: $kern_fn does not appear to have an MTD map table\n"
    unless(check_sym('em86xxmap_partitions'));

# Extract the symbol table pointers, and the locations of the segment
# boundaries

my $arena	= get_words_sym(\*KERN, 'arena', 1);
my $mtd_map	= get_words_sym(\*KERN, 'em86xxmap_partitions', 1);

print "               Arena\n";
printf "%10s  %10s %10s\n", 'Address', 'Size (hex)', 'Size (dec)';
foreach my $i (1..5) {
    my @data = get_words(\*KERN, $arena, 3);
    my $size = $data[2];
    my $size_str;
    if($size == 0xffffffff) {
	$size_str = sprintf '%10s %10s', 'From ROMFS', 'From ROMFS';
    } else {
	$size_str = sprintf '0x%08x %10u', $size, $size;
    }
    printf "0x%08x: %s %s\n",
	    $data[1], $size_str, ($data[0] ? 'RW' :'RO')
	if($data[1]);
    $arena += 40;
}

print "\n";

my $last_end = 0;
print "               MTD Partitions\n";
printf "%9s %10s  %10s %10s\n", 'Device', 'Offset', 'Size (hex)', 'Size (dec)';
foreach my $i (1..5) {
    my @data = get_words(\*KERN, $mtd_map, 3);
    my $offset = $data[2];
    $offset = $last_end if($offset == 0xffffffff);
    my $size = $data[1];
    $last_end = $offset + $size;
    my $name = get_str(\*KERN, $data[0]);
    printf "/dev/mtd%d 0x%08x: 0x%08x %10u %s\n",
	    $i, $offset, $size, $size, $name;
    $mtd_map += 20;
}

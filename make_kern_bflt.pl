#!/usr/bin/perl -w

=pod

=head1 NAME

make_kernel_bflt - convert a Beyonwiz kernel image into a bFLT executable


=head1 SYNOPSIS

    make_kernel_bflt --reloc=<value> -r=<value> kernel_image

=head1 DESCRIPTION

Takes a single file name argument, the name of a Beyonwiz DP series kernal,
and produces a copy of that file with a bFLT header, and with the
contents of the kernel moved in the file so that the file addresses
for the bFLT file are the same as the actual memory addresses.
The output file name is the input file name with the extension
B<.bflt> added.

Prints a table of the kernel segment locations, with B<mem addr>
for the kernel memory address, B<file addr> for the image file
location, and B<reloc addr> for the location in the bFLT file.

When the kernel start address is the default 0x90090000,
the output file will look to be about 2GB, but most of its blocks
won't have been written to; on NTFS and Linux file systems,
the physical representation of a file like that is much smaller than 2GB.

=head1 ARGUMENTS

B<Make_kernel_bflt> takes the following arguments:

=over 4

=item reloc

  --reloc=value
  -r=value

Locates the kernel image to start at the location given by <value>.
If the relocation location isn't given, the kernel image is moved
to start at the value of the C<_stext> symbol, 0x90090000.

The value may be written, equivalently, in the forms 64, 0x40, 0100
or 0b1000000.

This was intended to allow the B<arm2html> disassembler to carry out
disassembly giving all the correct memory locations.
Unfortunately, arm2html crashes with a start address as large as 0x90090000.
A reasonable compromise is to specify B<-r 0x90000>,
which makes for  addresses that are easy to convert to the correct value.

The first 64 bytes of the relocated file are the bFLT header,
and so code can't be written into the first 64 bytes.
B<make_kernel_bflt> allows the relocation value to be less than 64
(B<-r 0>, for example), but the header effectively over-writes the
first 64 bytes of the code.

=back

=head1 PREREQUSITES

Uses package C<Getopt::Long>, C<POSIX>
and L<C<Beyonwiz::Kernel>|Kernel>.

=head1 BUGS

Tries to use some contextual information to ensure that
the correct values for the location of the symbol table
and the segment boundaries have been found. These hueristics may fail
and the program may produce garbage.

The fact that B<arm2html> doesn't work with the code start set to
the default 0x90090000 prevents B<make_kernel_bflt>
from being used as it was intended to be used for that disassembler.

B<Arm2html> crashes if the relocation segment of the bFLT file is empty.
B<Make_kernel_bflt> creates a single fake entry to relocate its first word
to stop B<arm2html> crashing.
This is more a workaround for a bug in B<arm2html> than a bug
in B<make_kernel_bflt>

=cut

use strict;

use POSIX;
use Getopt::Long;

use Beyonwiz::Kernel
	qw(check_magics get_words_sym);

Getopt::Long::Configure qw/no_ignore_case bundling/;

use constant BUFSZ => 0x4000;

my $reloc;

sub usage() {
    die "Usage: $0 [--reloc=relocval] [-r=relocval] BW-kernel-file\n";
}

GetOptions('reloc|r=s' => \$reloc) or usage;

die "The relocation address must be a decimal, hex, octal or binary number\n"
    if(defined($reloc) && $reloc !~ /^([0-9]+|0x[0-9a-fA-F]+|0[0-7]*|0b[01]+)/);

$reloc = oct($reloc) if(defined($reloc) && $reloc =~ /^0/);

@ARGV == 1 or usage;

my $bare = $ARGV[0];
my $bflt = $bare . '.bflt';

my $buf;

open BARE, '<', $bare or die "$bare: $!\n";

check_magics($bare, \*BARE);

my $fileLen = (stat BARE)[7];

# Memory locations where the memory addresses of the symbols needed to
# construct the bFLT header are stored. Initialised using get_words_sym().

my %data = map { $_ => get_words_sym(\*BARE, $_, 1) } qw (
    _stext
    _text
    _etext
    _edata
    __bss_start
    _end
);

my @bfltValues = qw/_stext _etext __bss_start _end/;

# The bss symbol can be past the end of the file...
#$data{__bss_start} = $fileLen + $data{_stext}
#    if($data{__bss_start} > $fileLen + $data{_stext});

# Sanity check on ordering of addresses: _stext <= _etext <= __bss_start <= _end

foreach my $i (0..$#bfltValues-1) {
    $data{$bfltValues[$i]} <= $data{$bfltValues[$i+1]}
	or die sprintf "%s (0x%08x) > %s (0x%08x)\n",
		$bfltValues[$i], $data{$bfltValues[$i]},
		$bfltValues[$i+1], $data{$bfltValues[$i+1]},
}

$reloc = $data{_stext} if(!defined $reloc);

my $bfSeek = 0;

if($reloc < 64) {
    $bfSeek = 64-$reloc ;
    $reloc = 64 
}

my $roff = -$data{_stext} + $reloc;

# Print the resulting values

printf "%12s: %10s %10s %10s\n",
    'sym', 'mem addr', 'file addr', 'reloc addr';
foreach my $val (@bfltValues) {
    printf "%12s: 0x%08x 0x%08x 0x%08x\n",
	$val, $data{$val}, $data{$val}-$data{_stext}, $data{$val}+$roff;
}

# Pack the header: 4 bites ASCII, 9 little-ending longs, 24 bytes padding
# to make up 64 bytes of header

my $bfHdr = pack 'a4 N9 x24', (
		'bFLT',
		4,
		$data{_stext}        + $roff,
		$data{_etext}        + $roff,
		$data{__bss_start}   + $roff,
		$data{_end}          + $roff,
		0x4000,				# Fake stack size
		$data{__bss_start}   + $roff,	# Fake relocation start
		1,				# Fake relocation size
		1,				# FLAT_FLAG_RAM
	    );

open bFLT, '>' . $bflt or die "$bflt: $!\n";

# Write the header

syswrite bFLT, $bfHdr;

# Seek to the start address of the kernel

sysseek bFLT, $data{_stext} + $roff, SEEK_SET;

# Read in the first 16kB of the kernel image

sysseek BARE, 0, SEEK_SET;

sysread(BARE, $buf, BUFSZ) == BUFSZ
    or die "$bare is much too small to be a uClinux kernel image\n";

# Write the data already read & processed, then the rest of the file

syswrite bFLT, $buf, length($buf)-$bfSeek, $bfSeek;

while(sysread BARE, $buf, BUFSZ) {
    syswrite bFLT, $buf;
}

# The arm2html disassembler dies if there's no relocation information,
# so add a fake entry to relocate the first word in the image.

$buf = pack 'N', ($data{_stext} + $roff);
syswrite bFLT, $buf;

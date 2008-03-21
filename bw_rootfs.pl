#!/usr/bin/perl -w

=pod

=head1 NAME

bw_rootfs - extract or update the root filesystem romfs image in an
uncompressed Beyonwiz kernel.


=head1 SYNOPSIS

    bw_rootfs [-u|--update] [-c|--checkonly] [-f|--force] beyonwiz_uncompressed_kernel [romfs_name]

=head1 DESCRIPTION

Either extract the ROMFS root file system embedded in an uncompressed
Beyonwiz kernel to I<romfs_name>, or update (B<-u> or B<--update>)
the existing root file system from I<romfs_name>.

When the ROMFS root file system is extracted, the file size is zero-padded
to the next 1024-byte boundary, for compatibility with genromfs and loopback
mounting of the ROMFS image on systems that support it.

The size of the update file is limited. The ROMFS image start in the kernel is
aligned to a 4096-byte boundary, and its size is padded out to an integral
number of 4096-byte pages. Since the size of the ROMFS image itself is an
integral number of 16-byte blocks, there is never more than
4080 (4096 - 16) bytes of spare space in the kernel to accept a larger
ROMFS image, and there is typically less.

B<bw_rootfs> prints the location, size, and padded file size for the
embedded root ROMFS, and the amount of spare space
available for an update and the maximum size update that B<-u> will accept.
It also checks that the padding from the end of the ROMFS image to the
next page boundary is all zero bytes, and prints a warning if it isn't.

On an update, B<bw_rootfs> will not update the file if the padding check fails
or if the size of the update is larger than the space available. Both
these checks can be over-ridden with the B<-f> flag.

If the B<-c> flag is used, only the checking and information printout
is performed, the ROMFS image is not extracted, and the kernel is not updated.
If B<-c> is specified, but B<-u> us not, then the I<romfs_name> must not be
specified; in all other cases it must be present.


=head1 ARGUMENTS

B<bw_rootfs> takes the following arguments:

=over 4

=item update

  -u
  --update

Normally the ROMFS image contained in I<beyonwiz_uncompressed_kernel>
is extracted into I<romfs_name>.
When B<-u> is set, the ROMFS image in I<beyonwiz_uncompressed_kernel>
is updated from I<romfs_name>, subject to the checks described above.

=item checkonly

  -c
  --checkonly

Only print information about the ROMFS image, and perform checks.
May be used with B<-u> to check whether an update will fit in the available
space in the kernel.

=item force

  -f
  --force

Ignore the checks for zero-padding and the size of the update
and perform the operation anyway.

=back

=head1 PREREQUSITES

Uses packages C<Getopt::Long> and L< C<BWFW>|BWFW/NAME >.

=head1 BUGS

B<Not tested by the author to do an update on a firmware module that
has actually been run in a Beyonwiz PVR.>

Heuristics to find the embedded ROMFS root filesystem may fail,
and cause the update or extraction to fail, extract the wrong data or
insert the update in the wrong location.

The presumption of 4096-byte page alignment and round-up may be incorrect.

The amount of space available for an update may be small.  This isn't
actually a bug in B<bw_rootfs>, but it is an important limitation.

Using the B<-f> option may cause the resulting kernel to crash when
run in a Beyonwiz, requiring the use of the

=for html <a href="http://www.beyonwiz.com.au/phpbb2/viewtopic.php?t=1298">
Beyonwiz emergency firmware update procedure</a>

=for text Beyonwiz emergency firmware update procedure
(http://www.beyonwiz.com.au/phpbb2/viewtopic.php?t=1298)

which is only supported on a Windows PC.

If a kernel is updated with a I<smaller> ROMFS image than the original,
that may lose the record of the orignal amount of space allocated to
the image in the kernel, and may prevent (without the use of B<-f>) a
larger (but safe) sized ROMFS image from being inserted in the kernel
to overwrite the smaller one. This is because the only information about
the allocated space for the ROMFS image is derived from the length field
in the ROMFS image itself.
It is recommended that the B<-u> option only be applied to Beyonwiz
kernels that have not already been updated using B<bw_rootfs>.

Changing the Beyonwiz root file system may itself result in a firmware
package that will fail to run correctly, and need the 

=for html <a href="http://www.beyonwiz.com.au/phpbb2/viewtopic.php?t=1298">
Beyonwiz emergency firmware update procedure</a>

=for text Beyonwiz emergency firmware update procedure
(http://www.beyonwiz.com.au/phpbb2/viewtopic.php?t=1298)

to restore it, but then if you're doing this
I hope you knew that already.

=cut

use strict;

# Extract the symbols published by the kernel for the module interface.

sub usage() {
    die "Usage: $0 [-u|--update] [-c|--checkonly] [-f|--force]",
        " beyonwiz_uncompressed_kernel [romfs_name]\n";
}

# BLOCKSZ is the alignment/block size for the embedded ROMFS
# ROMFSBLKSZ is the block size used in genromfs.

# The code assumes BLOCKSZ >= ROMFSBLKSZ

use constant BLOCKSZ	  => 4096;
use constant ROMFSMAGIC	  => '-rom1fs-';
use constant ROMFSBLKSZ   => 1024;

use constant ROMFSPADDING => '\0' x ROMFSBLKSZ;

use Getopt::Long;

use BWFW qw(BASE check_magics read_or_die write_or_die get_words_sym);

Getopt::Long::Configure qw/no_ignore_case bundling/;

# Either warn with, or die with, the message; die if $die is true.

sub warn_or_die($$) {
    my ($die, $mess) = @_;
    if($die) {
	die $mess;
    } else {
	warn $mess;
    }
}

# Round up to the next block size

sub roundup($$) {
    my ($size, $blksz) = @_;
    return int(($size + $blksz - 1) / $blksz) * $blksz;
}

# Find the location of the ROMFS root file system in the file handle $fh.
# $fn is the file name, and only used for error messages.
# First try to find it at the location pointed to by the rootROMFS symbol;
# if that fails search for the ROMFSMAGIC string ("-rom1fs-")

sub find_rootfs($$) {
    my ($fn, $fh) = @_;
    my $root_fs = get_words_sym($fh, 'rootROMFS', 1);
    my $buf;

    if(read_or_die($fn, $fh, $root_fs - BASE, \$buf, BLOCKSZ, 0)
    and unpack('a8', $buf) eq ROMFSMAGIC) {
	return ($root_fs - BASE, unpack('N', substr $buf, 8, 4), $buf)
    }

    $root_fs = 0;

    while(1) {
	read_or_die($fn, $fh, $root_fs, \$buf, BLOCKSZ, 1);
	return ($root_fs, unpack('N', substr $buf, 8, 4), $buf)
	    if(unpack('a8', $buf) eq ROMFSMAGIC);
	$root_fs += BLOCKSZ;
    }

}

# Check that the last block of the embedded ROMFS is all
# zeros after the end of the actual filesystem data.

sub check_lastfs_block($$$$) {
    my ($kern_fn, $kern_fh, $kpos, $size) = @_;
    my $buf;
    my $sum = 0;
    $kpos = $kpos + roundup($size, BLOCKSZ);
    read_or_die($kern_fn, $kern_fh, $kpos, \$buf, BLOCKSZ, 1);
    if($size % BLOCKSZ != 0) {
	my $off = $size % BLOCKSZ;
	my $len = BLOCKSZ - $off;

	# unpack '%32 a*' is a dirty but efficient way of checking that
	# the remainder of the block is all zero bytes; it calculates the
	# 32-bit sum of all the bytes in the remainder of the block. The
	# size of the block ensures that it can't overflow.

	$sum = unpack '%32 a*', substr $buf, $off, $len;

	print 'Warning: "spare" space after root',
		" filesystem is not all zeroed!\n"
	    if($sum != 0);
    }
    return $sum == 0;
}

# Extract the root file system (position $kpos, size $size) from
# from the file handle $kern_fh and write it to $root_fh.
# The first block of the file system is in the reference $buf.
# The _fn variables are the corresponding file names

sub extract_rootfs($$$$$$$) {
    my ($kern_fn, $kern_fh, $root_fn, $root_fh, $kpos, $size, $buf) = @_;
    my $left = $size;
    my $rpos = 0;
    $kpos += BLOCKSZ;
    write_or_die($root_fn, $root_fh, $rpos, $buf, BLOCKSZ, 1);
    $rpos += BLOCKSZ;
    $left -= BLOCKSZ;
    while($left > 0) {
	read_or_die($kern_fn, $kern_fh, $kpos, $buf, BLOCKSZ, 1);
	$kpos += BLOCKSZ;
	if($left < BLOCKSZ) {
	    if($left % ROMFSBLKSZ != 0) {
		my $newlen = roundup($left, ROMFSBLKSZ);
		substr($$buf, $left, $newlen-$left) =
			substr ROMFSPADDING, 0, $newlen-$left;
		$left = $newlen;
	    }
            write_or_die($root_fn, $root_fh, $rpos, $buf, $left, 1);
	} else {
            write_or_die($root_fn, $root_fh, $rpos, $buf, BLOCKSZ, 1);
	}
	$rpos += BLOCKSZ;
	$left -= BLOCKSZ;
    }
}

# Update the root file system (size $size) from
# from the file handle $root_fh and write it to $root_fh
# at the position $kpos.
# The _fn variables are the corresponding file names.

sub update_rootfs($$$$$$) {
    my ($kern_fn, $kern_fh, $root_fn, $root_fh, $kpos, $size) = @_;
    my $buf;
    my $left = $size;
    my $rpos = 0;
    while($left > 0) {
	read_or_die($root_fn, $root_fh, $rpos, \$buf,
	    ($left < BLOCKSZ ? $left : BLOCKSZ), 1);
	$rpos += BLOCKSZ;
	write_or_die($kern_fn, $kern_fh, $kpos, \$buf,
	    ($left < BLOCKSZ ? $left : BLOCKSZ), 1);
	$kpos += BLOCKSZ;
	$left -= BLOCKSZ;
    }
}

my ($uflag, $cflag, $fflag);

GetOptions(
	'u|update' => \$uflag,
	'c|checkonly' => \$cflag,
	'f|force' => \$fflag
    ) or usage;

(!$uflag && $cflag ? @ARGV == 1 : @ARGV == 2) || usage;

my $kern_fn = $ARGV[0];
my $root_fn = $ARGV[1];

open KERN, '<', $kern_fn or die "$0: $kern_fn - $!\n";

check_magics($kern_fn, \*KERN);

my ($pos, $size, $buf) = find_rootfs($kern_fn, \*KERN);
my $spare = roundup($size, BLOCKSZ) - $size;

# Print the location, size, and spare space for the file system

printf "Found rootfs at file location 0x%08x size: %d\n", $pos, $size;
printf "Romfs padded file size: %d\n",
    int(($size + ROMFSBLKSZ - 1) / ROMFSBLKSZ) * ROMFSBLKSZ;
printf "Spare space: %d bytes\n", $spare;
printf "Maximum update size: %d bytes\n", $size + $spare;

if($uflag) {

    # Update the embedded root file system

    if(!check_lastfs_block($kern_fn, \*KERN, $pos, $size)) {
	if($fflag) {
	    warn "But proceeding anyway!\n" if(!$cflag);
	} else {
	    die "Root file system not updated!\n" if(!$cflag);
	}
    }

    # Check that there's enough spare space

    open ROOTFS, '<', $root_fn or die "$0: $root_fn - $!\n";

    my $root_size = (stat ROOTFS)[7];

    if($root_size > $size + $spare) {
	warn_or_die !$fflag, sprintf "$root_fn is too large (%d bytes)"
	    . " available space is (%d bytes)\n",
	    $root_size, $size + $spare;
	warn "But proceeding anyway!\n" if(!$cflag);
    }

    exit if($cflag);

    # Reopen the kernel file read/write and update the embedded
    # root filesystem

    close KERN;
    open KERN, '+<', $kern_fn or die "$0: $kern_fn - $!\n";

    update_rootfs($kern_fn, \*KERN, $ARGV[1], \*ROOTFS, $pos, $root_size);

} else {

    # Extract the embedded root file system

    # Check that the "spare" space is all zeros

    check_lastfs_block($kern_fn, \*KERN, $pos, $size);

    exit if($cflag);

    # Do the extraction

    open ROOTFS, '>', $root_fn or die "$0: $root_fn - $!\n";

    extract_rootfs($kern_fn, \*KERN, $ARGV[1], \*ROOTFS, $pos, $size, \$buf);

    close ROOTFS;
}

close KERN;

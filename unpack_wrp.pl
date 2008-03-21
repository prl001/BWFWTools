#!/usr/bin/perl -w

=pod

=head1 NAME

unpack_wrp - unpack a Beyonwiz firmware update file


=head1 SYNOPSIS

    unpack_wrp [-i|--insens] [-f|--force] [-k|--keep] firmware_file flash_directory [root_directory]

=head1 DESCRIPTION

Extracts the files in I<firmware_file> (Beyonwiz C<.wrp> file) into
the directory I<flash_directory> as they would appear in the Beyonwiz's
C</flash> directory.
If the I<root_directory> argument is also given, the Beyonwix root
file system is extracted from the kernel image in C</flash>
into that directory.

The two-argument form does not hve any more functionality than
Eric Fry's C<wiz_unpack>.

=head1 ARGUMENTS

B<Make_kernel_bflt> takes the following arguments:

=over 4

=item insens

  --insens
  -i

Extracts in a mode that adds a prefix to file and directory names
so that files that only differ by the case of the characters in their name
(eg. C<Abc> vs C<abc>) are kept as distinct files.

This mode is automatically invoked on systems that normally have case-insensitive filenames, like Windows, Cygwin and Mac OS X.

=item force

  --force
  -f

Passed through to L< C<bw_rootfs>|bw_rootfs/> >.
Forces extraction in some cases where it would otherwise fail.

=item keep

  --keep
  -k

When the root file system is extracted, keep the files
C<linux.bin> and C<root.romfs>, which are otherwise deleted.

=back

=head1 PREREQUSITES

Uses packages C<Getopt::Long>,
C<IO::Uncompress::Gunzip> and C<POSIX>.

Uses L< C<bw_rootfs>|bw_rootfs/> >.

Uses Eric Fry's wizfwtools program wiz_unpack.

=head1 BUGS

Tries to use some contextual information to find the root filesystem.
They may fail and the extraction of the root file system will fail.

=cut

use strict;

use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;
use Getopt::Long;

Getopt::Long::Configure qw/no_ignore_case bundling/;


sub usage() {
    die "Usage: $0 [-i|--insens] [-f|--force] [-k|--keep]\n"
}

my ($lingz, $lin, $rootfs);

my ($insens, $force, $keep);

sub on_exit() {
    foreach my $f ($lin, $rootfs) {
	unlink $f if(!$keep && defined $f);
    }
}

use constant LINGZ  => 'linux.bin.gz';
use constant LIN    => 'linux.bin';
use constant ROOTFS => 'root.romfs';

# Location of the perl scripts used in this script
# Correct installation depends on the format of the next line. Don't change it!
use constant PERLS     => '.';

# Make case insensitive by default on Windows and Mac OS X

$insens = 1 if($^O eq 'MSWin32' || $^O eq 'darwin' || $^O eq 'cygwin');

my $q = $^O eq 'MSWin32' ? '"' : "'";

GetOptions('i|insens' => \$insens,
           'f|force' => \$force,
	   'k|keep' => \$keep
    ) or usage;

my $wrp_unpack_args = $insens ? " -i" : "";
my $bw_rootfs_args = $force ? " -f" : "";

@ARGV == 2 or @ARGV == 3 or usage;

my ($wrp_fn, $flash_dir, $rootfs_dir) = @ARGV;

my $perl_dir = PERLS;

$SIG{$_} = \&on_exit foreach qw(HUP INT QUIT PIPE TERM __DIE__);

print "Extract application file system $wrp_fn into $flash_dir\n";

die "Target directory $flash_dir already exists\n"
    if(-e $flash_dir);
die "Target directory $rootfs_dir already exists\n"
    if(defined $rootfs_dir && -e $rootfs_dir);

system("wiz_unpack$wrp_unpack_args -x $q$flash_dir$q $q$wrp_fn$q") == 0
    or die "wiz_unpack of $wrp_fn into $flash_dir failed\n";

if(defined $rootfs_dir) {
    print "Extract root file system into $rootfs_dir\n";
    $lingz = $flash_dir . '/' . ($insens ? '001x_' : '') . LINGZ;
    $lingz = $flash_dir . '/' . '001r_' . LINGZ
	if($insens && !-e $lingz);
    $lin = $flash_dir . '/' . LIN;
    $rootfs = $flash_dir . '/' . ROOTFS;
    mkdir $rootfs_dir or die "Can't create $rootfs_dir: $!\n"
	if(!-d $rootfs_dir);
    gunzip($lingz => $lin, BinModeOut => 1)
	or die "gunzip of $lingz to $lin failed: $GunzipError\n";
    system("perl $q$perl_dir/bw_rootfs.pl$q$bw_rootfs_args"
		. " $q$lin$q $q$rootfs$q") == 0
	or die "Extraction of $rootfs from $lin failed\n";
    system("wiz_unpack$wrp_unpack_args -x $q$rootfs_dir$q $q$rootfs$q") == 0
	or die "wiz_unpack of $rootfs into $rootfs_dir failed\n";
}

on_exit();

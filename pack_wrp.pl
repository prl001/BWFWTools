#!/usr/bin/perl -w

=pod

=head1 NAME

pack_wrp - pack a Beyonwiz firmware update file


=head1 SYNOPSIS

    pack_wrp [-t type|--machtype=type] [-T code|--machcode=code] [-i|--insens]
             [-f|--force] [-k|--keep] [-V volume|--volname=volume]
             [-v version|--version=version] [-s suffix|--versionsuffix=suffix]
	     [-p|-perlgzip] [-g|-gzip]
	     firmware_file flash_directory [root_directory]


=head1 DESCRIPTION

Packs the files in I<flash_directory>, and optionally in I<root_directory>
into I<firmware_file> (Beyonwiz C<.wrp> file).

If the I<root_directory> file is given, C<linux.bin.gz> in
I<flash_directory> is unzipped and the ROMFS root filesystem constructed
from I<root_directory> is patched into the kernel.
See L< C<bw_rootfs>|bw_rootfs/ > for more details.

The root file system can only be updated if there is enough spare space for
it in the kernel.
There will never be more than 4080 bytes spare, usually less.
See L< C<bw_rootfs>|bw_rootfs/ > for more details.

=head1 ARGUMENTS

B<Make_kernel_bflt> takes the following arguments:

=over 4

=item insens

  --insens
  -i

Packs in a mode that strips a prefix added to file and directory names
so that files that only differ by the case of the characters in their name
(eg. C<Abc> vs C<abc>) are guaranteed to remain as distinct files.
If I<flash_directory> and I<root_directory> haven't been constructed using
the case-insensitive modes of L< C<unpack_wrp>|unpack_wrp/ >, using
this option is likely to result in badly mangled filenames and
a C<.wrp> file that will cause a Beyonwiz to be unbootable.

This mode is automatically invoked on systems that normally have case-insensitive filenames, like Windows, Cygwin and Mac OS X.

=item machtype

  --machtype=type
  -t type

Set the machine type in the C<.wrp> firmware file header.
I<type> must be one of B<s>, B<p> or B<h> for the DP-S1, DP-P1
and DP-H1 Beyonwiz models respectively.

If neither I<machtype> nor I<machcode> is specified, the name of the file
in I<flashdir>C</version> is checked for the machine type, and I<machtype>
is set from that.

If both I<machtype> and I<machcode> are set, both corresponding options
are passed C<wiz_pack>, and it determines their precedence.

Setting the wrong type or code for firmware is likely to make the
Beyonwiz unbootable if the firmware is installed.
With this interface, you shouldn't have to use I<machtype> or I<machcode>
unless the machine type can't be detected automatically.

=item machcode

  --machcode=code
  -T code

Set the 16-digit hexadecimal System ID code
(L<http://www.openwiz.org/wiki/Hardware#System_IDs>)
for the firmware.
Don't use the spaces that appear in the codes on the Web page in the argument.

One of either I<machtype> or I<machcode> must be specified.

Setting the wrong type or code for firmware is likely to make the
Beyonwiz unbootable if the firmware is installed.

See I<machtype> above about the automatic detection of the machine type.

=item force

  --force
  -f

Passed through to L< C<bw_rootfs>|bw_rootfs/ >.
Forces update of the root file system in some cases where it
would otherwise fail.

=item keep

  --keep
  -k

When the root file system is constructed, keep the
temporary file C<flashI<nnn>> (in C</tmp> on Unix-like systems
and C<C:\Windows\Temp> on Windows).

C<linux.bin> and C<root.romfs> in I<flash_directory> are deleted anyway,
so that they aren't packaged into the firmware.

=item volname

  --volname=volume
  -V volume

Set the volume name of the ROMFS file systems. Both the flash and the root
file systems are given the same name. Defaults to B<mambo>,
the same as Beyonwiz original firmware.

=item version

  --version=version
  -v version

Set the firmware version string displayed in the firmware verification
popup on the Beyonwiz when the firmware is downloaded.
Should be set to something that indicates that the firmware is patched!

Defaults to I<xxx.yyy.zzz>I<suffix> where I<xxx.yyy.zzz> is
the Beyonwiz base version number embedded in the name of the file
in I<flashdir>C</version>, if it can be extracted, and I<suffix>
is a suffix to indicate the nature of the repacked firmware.
Suffix is set by B<--versionsuffix>.

If no version number can be extracted from I<flashdir>C</version>,
no version option is passed to C<wiz_pack> and C<wiz_pack>'s default
version number is used.

=item versionsuffix

  --versionsuffix=suffix
  -v suffix

Set the suffix denoting the nature of the repacked firmware to be added
to an automatically extracted version number,
as described above in B<version>.

Defaults to '__wiz_pack'.

=item compress

  --compress=level
  -c level

Set the I<gzip> compression level to I<level> when the kernel binary
is recompressed after an update.
The default is to use the I<gzip> default compression level.
I<Level> must be in the range 1..9; 9 for best compression.

Beyonwiz kernels appear to be compressed at level 8.
The I<gzip> default is level 6.

I<Gzip> is only invoked if I<root_directory> is specified,
otherwise the kernel binary is not modified.

=item perlgzip, gzip

  --perlgzip
  -p
  --gzip
  -g

Normally, C<pack_wrp> tries to compress the kernel with the
GNU C<gzip> program, then if that fails, by using the Perl
C<IO::Compress::Gzip> library.

These options force the use of only one of the two compression mechanisms.


=back

=head1 PREREQUSITES

Uses packages C<Getopt::Long>,
C<IO::Compress::Gzip>, C<IO::Uncompress::Gunzip> and C<POSIX>.

Uses L< C<bw_rootfs>|bw_rootfs/ >.

Uses Eric Fry's wizfwtools programs C<wiz_pack>
and C<wiz_genromfs>.

Tries GNU C<gzip>, C<IO::Compress::Gzip> to compress the kernel
image unless one of B<--perlgzip> or B<--gzip> is used.

=head1 BUGS

Tries to use some contextual information to find the root filesystem.
They may fail and the updating of the root file system will fail.

Because of the way the root file system is patched into the kernel,
if you want to make I<other> patches to the kernel and update the
root filesystem, you have to ungzip C<linux.bin.gz>, make
the patches, and then regzip the kernel.
If you patch C<linux.bin> and don't gzip it back into
C<linux.bin.gz> those changes will be lost in the three-argument
form of C<pack_wrp>.

Using high compression levels for the kernel file is not yet tested.

Has too many options.

=cut

use strict;

use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use IO::Compress::Gzip qw(gzip $GzipError);

use Getopt::Long;

Getopt::Long::Configure qw/no_ignore_case bundling/;


sub usage() {
    die "Usage: $0\n"
      . "          [-t type|--machtype=type] [-T code|--machcode=code]\n"
      . "          [-i|--insens] [-f|--force] [-k|--keep]\n"
      . "          [-V volume|--volname=volume] [-v version|--version=version]\n"
      . "          [-c level|compress=level] [-s suffix|--versionsuffix=suffix]\n"
      . "          [-p|-perlgzip] [-g|-gzip]\n"
      . "          firmware_file flash_directory [root_directory]\n";
}

my ($lingz, $lin, $rootfs, $flashfs);

my ($insens, $force, $keep, $volname, $machtype, $machcode, $compresslevel)
 = (undef,   undef,  undef, 'mambo',  undef,     undef,     undef);
my ($version, $versionsuffix, $perlgzip, $gzip)
 = (undef,    '__wiz_pack',   undef,      undef);

sub on_exit() {
    foreach my $f ($lin, $rootfs, $flashfs) {
	unlink $f if(!$keep && defined $f);
    }
}

use constant LINGZ     => 'linux.bin.gz';
use constant LIN       => 'linux.bin';
use constant ROOTFS    => 'root.romfs';
use constant TMP       => $^O eq 'MSWin32' ? 'c:/Windows/Temp' : '/tmp';
use constant MAX_FLASH => 8*1024*1024 - 5 * 64 * 1024;

# Location of the perl scripts used in this script
# Correct installation depends on the format of the next line. Don't change it!
use constant PERLS     => '.';

# Use double quotes for quoting on Windows, otherwise single quotes

my $q = $^O eq 'MSWin32' ? '"' : "'";

sub do_gzip($$$$$) {
    my ($use_perlgzip, $use_gzip, $from, $to, $compresslevel) = @_;
    if(!$use_perlgzip) {
	my $compressflag = defined($compresslevel) ? " -$compresslevel " : '';
	if(system("gzip$compressflag -c $q$from$q > $q$to$q") != 0) {
	    my $mess = "gzip of $lingz to $lin failed";
	    if($use_gzip) {
		die $mess, "\n";
	    } else {
		warn $mess, " -- trying perl gzip\n";
	    }
	}
    }
    if(!$use_gzip) {
	my @compresslevel;
	@compresslevel = (-Level => $compresslevel) if($compresslevel);
	gzip($from => $to, BinModeIn => 1, @compresslevel)
	    or die "perl gzip of $lingz to $lin failed: $GzipError\n";
    }
}

# Make case insensitive by default on Windows and Mac OS X

$insens = 1 if($^O eq 'MSWin32' || $^O eq 'darwin' || $^O eq 'cygwin');

GetOptions('i|insens' => \$insens,
           'f|force' => \$force,
	   'k|keep' => \$keep,
	   'V|volname:s' => \$volname,
	   'v|version:s' => \$version,
	   's|versionsuffix:s' => \$versionsuffix,
	   't|machtype:s' => \$machtype,
	   'T|machcode:s' => \$machcode,
	   'c|compress:n' => \$compresslevel,
	   'p|perlgzip' => \$perlgzip,
	   'g|gzip' => \$gzip,
    ) or usage;

my ($insens_prefix_x , $insens_prefix_r)
 = $insens ? ('001x_', '001r_') : ('', '');

@ARGV == 2 or @ARGV == 3 or usage;

my ($wrp_fn, $flash_dir, $rootfs_dir) = @ARGV;

if(!defined $machtype && !defined $machcode
|| !defined $version) {
    foreach my $ver (glob("$flash_dir/${insens_prefix_x}version/*-romfs.bin"),
		     glob("$flash_dir/${insens_prefix_r}version/*-romfs.bin")) {
	if(!defined $machtype && !defined $machcode && $ver =~ /-(DP[SPH]1)-/) {
	    my $type = $1;
	    substr $type, 2, 0, '-';
	    $machtype = substr $type, 3, 1;
	    $machtype =~ y/SPH/sph/;
	    print "Using default machine type $type (--machtype=$machtype)\n";
	}
	if(!defined $version && $ver =~ /DP[SPH]1-([^\-]*)-romfs.bin/) {
	    $version = $1.$versionsuffix;
	    print "Using default version $version (--version=$version)\n";
	}
    }
}

defined $machtype or defined $machcode
    or die "Machine type must be specified with -t/--machtype",
	   " or -T/--machcode\n";

my $wrp_pack_args = defined($machtype) ? " -t $machtype" : '';
   $wrp_pack_args .= " -T $machcode" if(defined $machcode);
   $wrp_pack_args .= " -V '$version'" if(defined $version);
my $bw_rootfs_args = $force ? " -f" : "";
my $wiz_genromfs_args =" -V '$volname'";
   $wiz_genromfs_args .= " -i" if($insens);

my $perl_dir = PERLS;

$SIG{$_} = \&on_exit foreach qw(HUP INT QUIT PIPE TERM __DIE__);

if(defined $rootfs_dir) {
    print "Construct root file system from $rootfs_dir\n";
    $lingz = $flash_dir . '/' . $insens_prefix_x . LINGZ;
    $lingz = $flash_dir . '/' . $insens_prefix_r . LINGZ
	if($insens && !-e $lingz);
    $lin = $flash_dir . '/' . LIN;
    $rootfs = $flash_dir . '/' . ROOTFS;
    system("wiz_genromfs$wiz_genromfs_args"
	    . " -d $q$rootfs_dir$q -f $q$rootfs$q") == 0
	or die "Generation of $rootfs from $rootfs_dir failed\n";
    gunzip($lingz => $lin, BinModeOut => 1)
	or die "gunzip of $lingz to $lin failed: $GunzipError\n";
    system("perl $q$perl_dir/bw_rootfs.pl$q$bw_rootfs_args"
	    . " -u $q$lin$q $q$rootfs$q") == 0
	or die "Update of $rootfs into $lin failed\n";
    do_gzip($perlgzip, $gzip, $lin => $lingz, $compresslevel);
    unlink $lin
	or die "Can't remove $lin $!\n";
    unlink $rootfs
	or die "Can't remove $rootfs $!\n";
}

print "Construct BW firmware file $wrp_fn from $flash_dir\n";

$flashfs = TMP . '/flash' . $$;

system("wiz_genromfs$wiz_genromfs_args"
	. " -d $q$flash_dir$q -f $q$flashfs$q") == 0
    or die "Generation of $rootfs from $rootfs_dir failed\n";
system("wiz_pack$wrp_pack_args -i $q$flashfs$q -o $q$wrp_fn$q") == 0
    or die "wiz_pack of $flashfs into $wrp_fn failed\n";

my $root_size = (stat $flashfs)[7];
defined $root_size
    or die "Can't get size of $flashfs: $!\n";

warn "$flashfs is too big to fit in BW flash memory: $root_size > ",
	MAX_FLASH, "\n"
    if($root_size > MAX_FLASH);

on_exit();

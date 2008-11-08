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

B<Pack_wrp> takes the following arguments:

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
I<type> should be one of C<DP-S1>, C<DP-P1>, C<DP-P2>, C<DP-H1>, 
C<FT-P1>, C<FT-H1>,  C<FC-H1> or C<FC-H1>.

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
You can use spares or hyphens between bytes for readability,
so the spaces that appear in the codes on the Web page
can be used in the argument.
Don't forget to quote the argument if it contains spaces!

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

Set the B<gzip> compression level to I<level> when the kernel binary
is recompressed after an update.
The default is to use the B<gzip> default compression level
if B<gzip> is used for compression, and 9 if the Perl C<IO::Compress::Gzip>
package is used.
The Perl package does not appear to compress as effectively as B<gzip>,
and even at level 9 its result is still slightly larger than for
B<gzip>'s default compression.
I<Level> must be in the range 1..9; 9 for best compression.

The B<gzip> default is level 6.

B<Gzip> is only invoked if I<root_directory> is specified,
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

Uses packages
C<Beyonwiz::Hack::Utils>,
C<Getopt::Long>,
C<IO::Compress::Gzip>,
C<IO::Uncompress::Gunzip> and
C<File::Spec::Functions>.

Uses L< C<bw_rootfs>|bw_rootfs/ >.

Uses Eric Fry's wizfwtools programs C<wiz_pack>
and C<wiz_genromfs>.

Tries GNU C<gzip>, C<IO::Compress::Gzip> to compress the kernel
image unless one of B<--perlgzip> or B<--gzip> is used.

=head1 BUGS

B<Using modified firmware on your Beyonwiz may make it unable to
operate correctly, or even start.
Some modifications are known to interfere with the correct
functioning of the Beyonwiz.>

If your Beyonwiz cannot start after you load modified firmware,
you may need to use the procedures in the
B<NOTICE - How to recover from FW update failure>
L<http://www.beyonwiz.com.au/phpbb2/viewtopic.php?t=1298>
procedure on the Beyonwiz forum.
It's not known whether that procedure will fix all 
failures due to user modifications or "hacks".

If you run modified firmware on your Beyonwiz, and have
problems with its operation, try to reproduce
any problems you do have on a Beyonwiz running unmodified firmware,
or at least mention the modifications you use when reporting the
problem to Beyonwiz support or on the Beyonwiz Forum
L<http://www.beyonwiz.com.au/phpbb2/index.php>.
Beyonwiz support may not be able to assist if you are running anything
other than unmodified firmware from Beyonwiz.
Forum contributers may be able to be more flexible, but they will
need to know what modifications you have made.

Tries to use some contextual information to find the root filesystem.
They may fail and the updating of the root file system will fail.

Because of the way the root file system is patched into the kernel,
if you want to make I<other> patches to the kernel and update the
root filesystem, you have to ungzip C<linux.bin.gz>, make
the patches, and then regzip the kernel.
If you patch C<linux.bin> and don't gzip it back into
C<linux.bin.gz> those changes will be lost in the three-argument
form of C<pack_wrp>.

Has too many options.

In the three-argument form of C<pack_wrp> is used on Windows, the
temporary copy of linux.bin cannot be deleted (it may be being kept
open internally by Perl). This is a fatal error on other systems, but
on Windows, a non-fatal warning is issued. You may want to clean the
file up manually.

=cut

use strict;
use warnings;

use Beyonwiz::Hack::Utils qw(pathTildeExpand);

use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use IO::Compress::Gzip qw(gzip $GzipError);
use File::Spec::Functions qw(catfile tmpdir);

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
use constant LIN       => 'linux.bin' . $$;
use constant ROOTFS    => 'root.romfs';

# Flash is 8MB, but 5 x 64-kB segments are reserved for other uses
use constant MAX_FLASH => 8 * 1024*1024 - 5 * 64 * 1024;

sub system_redirect(@) {
    my @cmd = @_;
    my $outfile = pop @cmd;
    if(my $pid = fork) {
	# Parent - successful fork
	# Forks aren't real in Windows.
	# In particular, file descriptors remain shared,
	# so the parent must save and restore STDOUT!
	# Ugly, no?
	# However, this still seems to leave $outfile open,
	# which may be the reason why $lin can't be deleted
	open SAVESTDOUT, '>&', \*STDOUT
		or die "Can't dup STDOUT to save it\n"
	    if($^O eq 'MSWin32');

	waitpid($pid, 0);
	my $status = $?;

	open STDOUT, '>&', \*SAVESTDOUT
		or die "Can't restore STDOUT from dup\n"
	    if($^O eq 'MSWin32');

	return $status;
    } else {
	# Child or fork failed in parent
	die "Fork failed: $!\n" unless(defined($pid));

	# Child
	open STDOUT, '>', $outfile
	    or die "Can't open $outfile: $!\n";
	exec { $cmd[0] } @cmd
	    or die "Can't run $cmd[0]: $!\n";
	# not reached
    }
}

sub do_gzip($$$$$) {
    my ($use_perlgzip, $use_gzip, $from, $to, $compresslevel) = @_;
    $compresslevel = 9 if(!defined $compresslevel);
    if(!$use_perlgzip) {
	my $compressflag = "-$compresslevel";
	if(system_redirect('gzip', $compressflag, '-c', $from, $to) == 0) {
	    $use_gzip = 1; # Succcessful, don't retry using perl gzip
	} else {
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
	@compresslevel = (-Level => $compresslevel);
	gzip($from => $to, BinModeIn => 1, @compresslevel)
	    or die "perl gzip of $lingz to $lin failed: $GzipError\n";
    }
}

# Work around a bug in Gunzip::gunzip() in Cygwin perl 5.10.0

sub mygunzip($$@) {
    my ($infile, $outfile, @opts) = @_;
    my $gz = new IO::Uncompress::Gunzip $infile;
    return undef if(!$gz);
    unless(open OUT, '>', $outfile) {
	$GunzipError = $!;
	return undef;
    }
    binmode OUT;

    my $buffer;
    my $nread;

    while (($nread = $gz->read($buffer, 16 * 1024)) > 0)
    {
	if(!defined syswrite(OUT, $buffer)) {
	    $GunzipError = $!;
	    return undef;
	}
    }

    return 1;
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
    foreach my $ver (glob(catfile($flash_dir, "${insens_prefix_x}version",
					"*-romfs.bin")),
		     glob(catfile($flash_dir, "${insens_prefix_r}version",
					"*-romfs.bin"))) {
	if(!defined $machtype
	&& !defined $machcode
	&& $ver =~ /-(DP[SPH][12]|F[TC][PH]1)-/) {
	    $machtype = $1;
	    print "Using default machine type $machtype",
		" (--machtype=$machtype)\n";
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

my @wrp_pack_args;
   push @wrp_pack_args, '-t', $machtype    if(defined $machtype);
   push @wrp_pack_args, '-T', $machcode    if(defined $machcode);
   push @wrp_pack_args, '-V', $version     if(defined $version);
my @bw_rootfs_args;
   push @bw_rootfs_args, '-f'              if($force);
my @wiz_genromfs_args = ('-V', $volname);
   push @wiz_genromfs_args, '-i'           if($insens);

$SIG{$_} = \&on_exit foreach qw(HUP INT QUIT PIPE TERM __DIE__);

pathTildeExpand();

if(defined $rootfs_dir) {
    print "Construct root file system from $rootfs_dir\n";
    $lingz = catfile($flash_dir, $insens_prefix_x . LINGZ);
    $lingz = catfile($flash_dir, $insens_prefix_r . LINGZ)
	if($insens && !-e $lingz);
    $lin = catfile(tmpdir, LIN);
    $rootfs = catfile($flash_dir, ROOTFS);
    system({'wiz_genromfs'}
	    'wiz_genromfs', @wiz_genromfs_args,
	    '-d', $rootfs_dir, '-f', $rootfs) == 0
	or die "Generation of $rootfs from $rootfs_dir failed\n";
    print "Insert the root file system into the kernel image $lingz\n";
    mygunzip($lingz => $lin, BinModeOut => 1)
	or die "gunzip of $lingz to $lin failed: $GunzipError\n";
    system({'perl'}
	    'perl', '-S', 'bw_rootfs.pl', @bw_rootfs_args,
		    '-u', $lin, $rootfs) == 0
	or die "Update of $rootfs into $lin failed\n";
    do_gzip($perlgzip, $gzip, $lin => $lingz, $compresslevel);

    # For some reason, Windows won't do this delete...
    # Warn instead of dying on Windows.
    unlink $lin
	or &{ $^O eq 'MSWin32'
		? sub {warn @_}
		: sub {die @_}}("Can't remove $lin $!\n");

    unlink $rootfs
	or die "Can't remove $rootfs $!\n";
}

print "Construct BW firmware file $wrp_fn from $flash_dir\n";

$flashfs = catfile(tmpdir, 'flash' . $$);

system({'wiz_genromfs'}
	'wiz_genromfs', @wiz_genromfs_args,
	'-d', $flash_dir, '-f', $flashfs) == 0
    or die "Generation of $rootfs from $rootfs_dir failed\n";
system({'wiz_pack'}
	'wiz_pack', @wrp_pack_args, '-i', $flashfs, '-o', $wrp_fn) == 0
    or die "wiz_pack of $flashfs into $wrp_fn failed\n";

my $root_size = (stat $flashfs)[7];
defined $root_size
    or die "Can't get size of $flashfs: $!\n";

if($root_size <= MAX_FLASH) {
    print "$wrp_fn uses: $root_size bytes; available: ", MAX_FLASH,
	"; spare: ", MAX_FLASH - $root_size, "\n";
} else {
    unlink $wrp_fn if(!$keep);
    warn "$wrp_fn is too big to fit in BW flash memory: $root_size > ",
	    MAX_FLASH, "\n",
	 ($keep ? '' : "	- firmware .wrp file not created\n");

}

on_exit();

exit(0);

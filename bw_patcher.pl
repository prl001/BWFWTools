#!/usr/bin/perl -w

=pod

=head1 NAME

bw_patcher - pack a Beyonwiz firmware update file


=head1 SYNOPSIS

    bw_patcher [-t type|--machtype=type] [-T code|--machcode=code] [-i|--insens]
             [-f|--force] [-k|--keep] [-V volume|--volname=volume]
             [-v version|--version=version] [-s suffix|--versionsuffix=suffix]
	     [-p|-perlgzip] [-g|-gzip]
	     firmware_file patched_firmware_file patch_modules...


=head1 DESCRIPTION

Applies the firmware patches in the I<patch_modules> to I<firmware_file>
and creates a new version of the firmware in I<patched_firmware_file>.

Uses BWFWTools L< C<unpack_wrp>|unpack_wrp/ >
and
L< C<pack_wrp>|pack_wrp/ >
to unpack and re-pack the firmware file after applting the patches.
Most of the options to B<bw_patcher> are passed through to those
programs as applicable.

=head1 ARGUMENTS

B<Bw_patcher> takes the following arguments:

=over 4

=item insens

  --insens
  -i

=item machtype

  --machtype=type
  -t type

=item machcode

  --machcode=code
  -T code

=item force

  --force
  -f

=item keep

  --keep
  -k

=item volname

  --volname=volume
  -V volume

=item version

  --version=version
  -v version

=item versionsuffix

  --versionsuffix=suffix
  -v suffix

=item compress

  --compress=level
  -c level

=item perlgzip, gzip

  --perlgzip
  -p
  --gzip
  -g

All the above options are passed through as the corresponding options to
L< C<unpack_wrp>|unpack_wrp/ >
and
L< C<pack_wrp>|pack_wrp/ >
as appropriate.

=item keep

  --keep
  -k

Keep the unpacked firmware directories in the system temporary directory.
Not passed through to 
L< C<unpack_wrp>|unpack_wrp/ >
or
L< C<pack_wrp>|pack_wrp/ >.

=back

=head1 PATCH MODULES

The I<patch_modules> are Perl modules that are loaded and used to apply
the necessary patches to the unpacked firmware.
The modules distributed with B<bw_patcher> are in the package
C<Beyonwiz::Hack>, but any module that implements the function
C<hack($flash_dir, $root_dir)> can be used.
The two arguments are the directories holding the C</flash> and
C</> (root) file systems unpacked from the firmware.
The function typically modifies C<etc/rc.sysinit> in C<$root_dir>,
and may add new files to, or overwrite files in, either firmware directory.

The modules packaged with B<bw_patcher> are
L<C<Beyonwiz::Hack::Telnet>|Telnet>,
L<C<Beyonwiz::Hack::BwhackSupport>|BwhackSupport>
and
L<C<Beyonwiz::Hack::USBHackSupport>|USBHackSupport>.

=head1 PREREQUSITES

Uses packages C<Getopt::Long>,
C<IO::Compress::Gzip>, C<IO::Uncompress::Gunzip> and C<POSIX>.

Uses L< C<unpack_wrp>|unpack_wrp/ >,
L< C<pack_wrp>|pack_wrp/ >
and
L< C<bw_rootfs>|bw_rootfs/ >.

Uses Eric Fry's wizfwtools programs C<wiz_pack>
and C<wiz_genromfs>.

C<Getopt::Long>,
C<File::Spec::Functions>,
C<File::Path>,
C<Carp>,
and
L<C<Beyonwiz::Hack::Utils>|Utils>.

=head1 BUGS

B<Using I<bw_patcher> (or any other method) to create a modified
version of the firmware for any Beyonwiz model can result in a
firmware package that can cause the Beyonwiz firmware to fail
completely.>

Tries to use some contextual information to find the root filesystem.
They may fail and the updating of the root file system will fail.

Also see the BUGS entry for the tools that B<bw_patcher> uses.

=cut

use strict;
use warnings;

use Getopt::Long;
use File::Spec::Functions qw(catfile tmpdir);
use File::Path;
use Carp;
use Beyonwiz::Hack::Utils qw(insens);

Getopt::Long::Configure qw/no_ignore_case bundling/;


sub usage() {
    die "Usage: $0\n"
      . "          [-t type|--machtype=type] [-T code|--machcode=code]\n"
      . "          [-i|--insens] [-f|--force] [-k|--keep]\n"
      . "          [-V volume|--volname=volume] [-v version|--version=version]\n"
      . "          [-c level|compress=level] [-s suffix|--versionsuffix=suffix]\n"
      . "          [-p|-perlgzip] [-g|-gzip]\n"
      . "          source_fw.wrp hacked_fw.wrp hack_names...\n";
}

my ($lingz, $lin, $rootfs, $flashfs);

my ($insens, $force, $keep, $volname, $machtype, $machcode, $compresslevel)
 = (undef,   undef,  undef, undef,    undef,     undef,     undef);
my ($version, $versionsuffix, $perlgzip, $gzip,  $help)
 = (undef,    undef,          undef,      undef, undef);

# Use double quotes for quoting on Windows, otherwise single quotes

my $q = $^O eq 'MSWin32' ? '"' : "'";

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
	   'h|help' => \$help,
    ) or usage;

$help and usage;

@ARGV >= 3 or usage;

my $unpack_opts;
$unpack_opts .= ' -i' if($insens);
$unpack_opts .= ' -f' if($force);

my $pack_opts;
$pack_opts .= ' -i' if($insens);
$pack_opts .= ' -f' if($force);
$pack_opts .= " -V $q$volname$q" if(defined $volname);
$pack_opts .= " -v $q$version$q" if(defined $version);
$pack_opts .= " -s $q$versionsuffix$q" if(defined $versionsuffix);
$pack_opts .= " -t $q$machtype$q" if(defined $machtype);
$pack_opts .= " -T $q$machcode$q" if(defined $machcode);
$pack_opts .= " -c $compresslevel" if(defined $compresslevel);
$pack_opts .= ' -p' if($perlgzip);
$pack_opts .= ' -g' if($gzip);

my ($insens_prefix_x , $insens_prefix_r)
 = $insens ? ('[0-9][0-9][0-9]x_', '[0-9][0-9][0-9]r_') : ('', '');

insens($insens);

my ($src_fw, $dst_fw) = (shift, shift);

my $flash_dir = catfile(tmpdir, 'flash' . $$);
my $root_dir  = catfile(tmpdir, 'root' . $$);

sub on_exit() {
    rmtree([$flash_dir, $root_dir]) if(!$keep);
}

$SIG{$_} = \&on_exit foreach qw(HUP INT QUIT PIPE TERM __DIE__);


system("unpack_wrp.pl$unpack_opts"
	. " $q$src_fw$q $q$flash_dir$q $q$root_dir$q") == 0
    or die "Unpack of $src_fw into $flash_dir and $root_dir failed\n";

while(my $hack_name = shift @ARGV) {
    eval "use $hack_name";
    croak "$@\n" if($@);
    eval $hack_name . "::hack('$flash_dir', '$root_dir')";
    croak "$@\n" if($@);
}

system("pack_wrp.pl$pack_opts"
	. " $q$dst_fw$q $q$flash_dir$q $q$root_dir$q") == 0
    or die "Packing $flash_dir and $root_dir into $src_fw failed\n";

on_exit();

#!/usr/bin/perl -w

=pod

=head1 NAME

bw_patcher - all-in-one tool to automatically apply Beyonwiz firmware patches


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
L<C<Beyonwiz::Hack::Telnet>|Beyonwiz::Hack::Telnet>,
L<C<Beyonwiz::Hack::Dim>|Beyonwiz::Hack::Dim>,
L<C<Beyonwiz::Hack::BackgroundChanger>|Beyonwiz::Hack::BackgroundChanger>,
L<C<Beyonwiz::Hack::BwhackSupport>|Beyonwiz::Hack::BwhackSupport>
and
L<C<Beyonwiz::Hack::USBHackSupport>|Beyonwiz::Hack::USBHackSupport>.

=head1 DISABLING THE HACKS

For instructions on disabling the hacks installed see the disabling
instructions in the documentation for the appropriate patch module.

B<Just installing an unmodified Beyonwiz firmware package may I<not>
actually disable the hack!>

=head1 PREREQUSITES

Uses packages
C<Getopt::Long>,
C<File::Spec::Functions>,
C<File::Path>,
C<Carp>,
and
L<C<Beyonwiz::Hack::Utils>|Beyonwiz::Hack::Utils>.

Uses L< C<unpack_wrp>|unpack_wrp/ >,
L< C<pack_wrp>|pack_wrp/ >
and
L< C<bw_rootfs>|bw_rootfs/ >.

Uses Eric Fry's wizfwtools programs C<wiz_pack>
and C<wiz_genromfs>.


=head1 BUGS

B<Using user extensions or hacks may make your Beyonwiz unable to
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

Also see the BUGS entries for the tools that B<bw_patcher> uses.

=cut

use strict;
use warnings;

use Getopt::Long;
use File::Spec::Functions qw(catfile tmpdir);
use File::Path;
use Carp;
use Beyonwiz::Hack::Utils qw(insens pathTildeExpand);

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

my @unpack_opts;
    push @unpack_opts, '-i'		    if($insens);
    push @unpack_opts, '-f'		    if($force);

my @pack_opts;
    push @pack_opts, '-i'		    if($insens);
    push @pack_opts, '-f'		    if($force);
    push @pack_opts, '-V', $volname	    if(defined $volname);
    push @pack_opts, '-v', $version	    if(defined $version);
    push @pack_opts, '-s', $versionsuffix   if(defined $versionsuffix);
    push @pack_opts, '-t', $machtype	    if(defined $machtype);
    push @pack_opts, '-T', $machcode	    if(defined $machcode);
    push @pack_opts, '-c', $compresslevel   if(defined $compresslevel);
    push @pack_opts, '-p'		    if($perlgzip);
    push @pack_opts, '-g'		    if($gzip);

my ($insens_prefix_x , $insens_prefix_r)
 = $insens ? ('[0-9][0-9][0-9]x_', '[0-9][0-9][0-9]r_') : ('', '');

insens($insens);

pathTildeExpand();

my ($src_fw, $dst_fw) = (shift, shift);

my $flash_dir = catfile(tmpdir, 'flash' . $$);
my $root_dir  = catfile(tmpdir, 'root' . $$);

sub on_exit() {
    rmtree([$flash_dir, $root_dir]) if(!$keep);
}

sub call_hack($$) {
    my ($proto, $hack_name) = @_;
    ($proto =~ /^\$\$\$*$/) or
	die $hack_name . "'s prototype ($proto) not permitted.",
            " \$ only in prototype\n";

    my $nargs = length($proto) - 2;
    $nargs <= @ARGV
	or die "Not enough earguments for $hack_name; requires $nargs,",
	    " only ", scalar(@ARGV), " supplied\n";

    my $exec_str = $hack_name . "::hack('$flash_dir', '$root_dir'";
    if($nargs > 0) {
	$exec_str .= join ', ', '', map { "'".$_."'" } @ARGV[0..$nargs-1];
	splice @ARGV, 0, $nargs;
    }
    $exec_str .= ')';

    eval $exec_str;
    croak "$@\n" if($@);

    my $hack_tag = eval $hack_name . "::hackTag()";
    croak "$@\n" if($@);
    return $hack_tag;
}

$SIG{$_} = \&on_exit foreach qw(HUP INT QUIT PIPE TERM __DIE__);

system({'perl'}
	'perl', '-S', 'unpack_wrp.pl', @unpack_opts,
					$src_fw, $flash_dir, $root_dir) == 0
    or die "Unpack of $src_fw into $flash_dir and $root_dir failed\n";

my @hack_tags;

while(my $hack_name = shift @ARGV) {
    eval "use $hack_name";
    croak "$@\n" if($@);
    my $proto = eval 'prototype \&' . $hack_name . "::hack";
    push @hack_tags, call_hack($proto, $hack_name);
}

if(!defined $versionsuffix and @hack_tags) {
    $versionsuffix = join('_', '', @hack_tags);
    push @pack_opts, '-s', $versionsuffix;
}

system({'perl'}
	'perl', '-S', 'pack_wrp.pl', @pack_opts,
					$dst_fw, $flash_dir, $root_dir) == 0
    or die "Packing $flash_dir and $root_dir into $src_fw failed\n";

on_exit();

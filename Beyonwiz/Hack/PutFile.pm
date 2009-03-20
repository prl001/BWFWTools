package Beyonwiz::Hack::PutFile;

=head1 NAME

Beyonwiz::Hack::PutFile - insert a hack file in the Beyonwiz firmware

=head1 SYNOPSIS

    Beyonwiz::Hack::PutFile;

A module to use as an argument to use with L< C<bw_patcher>|bw_patcher/ >.
Copies a file into the required relative location in either the root or the
flash file system..

=head1 DISABLING THE HACK

Download unmodified firmware into the Beyonwiz and
restart.

=head1 FUNCTIONS

=over

=item C<< hack($flash_dir, $root_dir, $filesystem, $src_file, $dest_file, $dest_exec) >>

Inserts C<$src_file> into the firmware filesystem
C<$filesystem> in the path C<$dest_file> relative
to the filesystem root.
Force C<$dest_file> to be executable if it doesn't already exist.

C<$filesystem> must be one of (B<root>, B<flash>).

The destination directory for the path must alteady exist in the firmware.
This is a bug.

=item C<< hackTag() >>

Returns C<bg> as the default suffix tag for the patch.

=back

=head1 PREREQUSITES

Uses packages
L<C<Beyonwiz::Hack::Utils>|Beyonwiz::Hack::Utils>.

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

The destination directory for the path must alteady exist in the firmware.

=cut

use strict;
use warnings;

use Beyonwiz::Hack::Utils qw(
	findNewFile
        copyFile
    );

sub hackTag() {
    return '';
}

sub hack($$$$$) {
    my ($flash_dir, $root_dir, $filesystem, $src_file,
	$dest_file, $dest_exec) = @_;
    die "$filesystem not a valid filesystem name. Only (root, flash) allowed\n"
	unless($filesystem eq 'root' || $filesystem eq 'flash');
    my $fs_dir = $filesystem eq 'root' ? $root_dir : $flash_dir;

    print "Copying $src_file to $dest_file in $fs_dir\n";

    my @dest_file = findNewFile($flash_dir, $dest_file, $dest_exec);

    die "Can't find $dest_file in $flash_dir\n"
	if(!@dest_file);
    die "Found too many copies of $dest_file in $flash_dir\n"
	if(@dest_file > 1);

    print "Putting $src_file as $dest_file[0]\n";
    copyFile($dest_file[0], $src_file, $dest_exec);
}

1;

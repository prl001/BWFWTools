package Beyonwiz::Hack::Dim;

=head1 NAME

Beyonwiz::Hack::Dim - hack to dim the front display

=head1 SYNOPSIS

    Beyonwiz::Hack::Dim;

A module to use as an argument to use with L< C<bw_patcher>|bw_patcher/>
to patch Beyonwiz firmware to dim the front panel display at startup.

The effect of this hack will be undone if you load
unmodified firmware onto the Beyonwiz.

=head1 USE IN BW_PATCHER

    Beyonwiz::Hack::Dim

=head1 FUNCTIONS

=over

=item C<< hack($flash_dir, $root_dir) >>

Called by L< C<bw_patcher>|bw_patcher/> to perform the patch.

Inserts the line:

    micomparam -q -r 500101

into the file that will be C</etc/rc.sysinit>, the system startup script,
on the Beyonwiz.
The line will be inserted just before the comment line:

    # rc.local

=item C<< hackTag() >>

Returns C<dim> as the default suffix tag for the patch.

=back

=head1 DISABLING THE HACK

Simply download unmodified firmware into the Beyonwiz and
restart.

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

=cut

use strict;
use warnings;

use Beyonwiz::Hack::Utils qw(findMatchingPath patchFile);

sub hackTag() {
    return 'dim';
}

# System init file to patch
my $sysfile  = 'etc/rc.sysinit';

# String to match on
my $match    = '# rc\.local';

# After string? (or before it)
my $after    = 0;

# Commands to patch in
my $patch    = <<'EOF';
	micomparam -q -r 500101
EOF

sub hack($$) {
    my ($flash_dir, $root_dir) = @_;
    print "Patching in Dim hack on $root_dir\n";

    my @sysinit = findMatchingPath($root_dir, $sysfile);

    die "Can't find $sysfile in $root_dir\n"
	if(!@sysinit);
    die "Found too many copies of $sysfile in $root_dir\n"
	if(@sysinit > 1);

    my $patches = patchFile($sysinit[0], $match, $patch, $after);
    die "Patch applied $patches times: should only be applied once!\n"
	if($patches != 1);
}

1;

package Beyonwiz::Hack::Codeset;

=head1 NAME

Beyonwiz::Hack::Codeset - hack to enable telnet access on the Beyonswz

=head1 SYNOPSIS

    Beyonwiz::Hack::Codeset;

A module to use as an argument to use with L< C<bw_patcher>|bw_patcher/>
to patch Beyonwiz firmware to make the Beyonwiz select a non-default
remote control codeset (so that multiple Beyonwizes in the same room
won't all respond to the one remote control.

The effect of this hack will be undone if you load
unmodified firmware onto the Beyonwiz.

=head1 USE IN BW_PATCHER

    Beyonwiz::Hack::Codeset codeset

The I<codeset> argument is an integer 0..7.

An unmodified Beyonwiz DP-P2 uses codeset 1.
Other Beyonwiz models use codeset 0.
These two codesets are the most convenient to use
if you have Beyonwiz BR-01 or BR-02 remote controls,
or a programmable remote that is restricted to codes from those
two remotes.

=head1 FUNCTIONS

=over

=item C<< hack($flash_dir, $root_dir, $codeset) >>

Called by L< C<bw_patcher>|bw_patcher/> to perform the patch.

Add the argument C<-rc $codeset> to all occurances of the I<wizdvp>
command in the file that will be C</etc/rc.sysinit>,
the system startup script,
on the Beyonwiz.

C<$codeset> must be in the range 0-7.
An unmodified Beyonwiz DP-P2 uses codeset 1.
Other Beyonwiz models use codeset 0.
These two codesets are the most convenient to use
if you have Beyonwiz BR-01 or BR-02 remote controls,
or a programmable remote that is restricted to codes from those
two remotes.

If you have a programmable remote that can accept hexcodes,
then any codeset can be used.
Beyonwiz codesets have the form C<0xBE0cxxxx> where C<BE0> is fixed,
C<c> is the codeset (0..7, not 0..F) and C<xxxx> is the command code.
For, example, with codeset 0 (all models except DP-P2),
the OK command is 0xBE001FE0,
with codeset 1 (DP-P2), it's 0xBE011FE0.
With codeset 5, it would be 0xBE051FE0,
but no Beyonwiz remote will operate that codeset.

=head2 Additional Code Sets in the DP-P2 Remote (BR-02)

The DP-P2 remote control (BR-02) is documented in the
DP-P2 manual as having codeset 1 (for the DP-P2) and codeset 0
(for other Beyonwiz models). Codeset 1 is selected by pressing and holding
the B<2> key while holding down B<OK> until the STB led flashes three times.
Codeset 0 is selected by instead holding down the B<1> key while holding
down B<OK>.

It is undocumented that the other six codesets (2-7) can be selected
on the remote by correspondingly holding down buttons B<3>-B<8> while
holding down B<OK>. Codeset 2 is selected by B<3> and correspondingly
for the other buttons to B<8>, which selected codeset 7.

This means that with this hack, up to eight Beyonwizes can be controlled
individually with a single BR-02 remote.

=item C<< hackTag() >>

Returns C<codeset> as the default suffix tag for the patch.

=back

=head1 DISABLING THE HACK

Simply download unmodified firmware into the Beyonwiz and
restart.

=head1 PREREQUSITES

Uses packages 
L<C<Beyonwiz::Hack::Utils>|Beyonwiz::Hack::Utils>.

=head1 BUGS

This hack cannot change the codeset for C<POWER> for startup
(though the shut-down C<POWER> will be changed),
the codes for the C<1+2+3+4+POWER> ot
the C<POWER> watchdog timer for power off,
because these codes are interpreted
in the front panel microcontroller,
not by the main firmware.

If you set a codeset for which you do not have a remote, then no remote
codes except POWERTOGGLE for startup (but not shutdown)
and the POWERTOGGLE 1+2+3+4 firmware recovery remote sequence
will work on the Beyonwiz.

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

use Beyonwiz::Hack::Utils qw(findMatchingPath substFile);

sub hackTag() {
    return 'codeset';
}

# System init file to patch
my $sysfile	= 'etc/rc.sysinit';

# String to match line
my $lineMatch	= '\./wizdvp -tgd ';

# Substitute pattern and its replacement
my $subsPattern	= '-tgd ';
my $repl	= '-tgd -rc ';

sub hack($$$) {
    my ($flash_dir, $root_dir, $codeset) = @_;
    print "Patching in Codeset hack on $root_dir\n";

    my @sysinit = findMatchingPath($root_dir, $sysfile);

    die "Can't find $sysfile in $root_dir\n"
	if(!@sysinit);
    die "Found too many copies of $sysfile in $root_dir\n"
	if(@sysinit > 1);

    ($codeset =~ /^[0-7]$/)
	or die "Codeset must be 0..7. Codeset $codeset supplied\n";

    my $patches = substFile($sysinit[0],
			$lineMatch, $subsPattern, $repl . $codeset . ' ', 0);
    print "Patch applied $patches times.\n";
}

1;

package Beyonwiz::Hack::BwhackSupport;

=head1 NAME

    Beyonwiz::Hack::BwhackSupport;

=head1 SYNOPSIS

A module to use as an argument to use with L< C<bw_patcher>|bw_patcher/ >.
It modifies the firmware to start a user-selectable set of hacks
that can be enabled/disabled using L< C<bwhack>|bwhack/ >.

The hacks available for enabling (default is all disabled) are:

=over 4

=item dim

The front panel display is run in a dimmer mode (as it is when on standby).

=item telnetd

Run I<telnetd> to allow login to the Beyonwiz using the I<telnet>
protocol.

=item wizremote

Enable Eric Fry's I<wizremote>
(L<http://www.beyonwizsoftware.net/software-b28/wizremote>)
on the Beyonwiz.

=item httproot

Enable HTTP access to whole BW.

The Beyonwiz root file system starts at
C<http://your_bw_ip_addr:49152/root>.
The Beyonwiz HTTP server doesn't allow directory
listing, so you have to know where you're navigating.

=back

The installation process modifies the Beyonwiz firmware startup script
C</etc/rc.sysinit> to copy the added
firmware file C</etc/rc.localcopy> into C</tmp/config/rc.localcopy>
each time the Beyonwiz starts.
C</tmp/config/rc.localcopy> is also copied into, and restored from,
non-volatile storage each time the Beyonwiz restarts.
C</etc/rc.sysinit> runs after this copy, so modifications to
C</tmp/config/rc.localcopy> will be overwritten each time the
Beyonwiz starts (and before C</tmp/config/rc.localcopy> has been run).
However, this means that even if you install an unmodified firmware package
on the beyonwiz, the patch will still be active, because running
C</tmp/config/rc.localcopy> is part of normal firmware startup.

The effect of this hack will I<not> be undone if you load
unmodified firmware onto the Beyonwiz.

=head1 FUNCTIONS

=over

=item C<< hack($flash_dir, $root_dir) >>

Called by L< C<bw_patcher>|bw_patcher/ > to perform the patch.

Inserts the lines:

    if [ ! -x /etc/rc.localcopy ]; then
            rm -f "${CONFIG_DIR}/rc.local"
            cp /etc/rc.localcopy "${CONFIG_DIR}/rc.local"
    fi

into the file that will be C</etc/rc.sysinit>, the system startup script,
on the Beyonwiz.
The line will be inserted just before the comment line:

    # rc.local

It also adds the new file C</etc/rc.localcopy> to the firmware.
This file actually implements the hack.

=back

=head1 DISABLING THE HACK

If the Beyonwiz is not running an unmodified firmware package,
download unmodified firmware into the Beyonwiz and
restart.

Enable only the C<telnet> hack using L< C<bwhack>|bwhack/ >
(installing unmodified firmware has not disabled the hacks):

    bwhack.pl --host=my.BW.IP.addr all off
    bwhack.pl --host=my.BW.IP.addr telnetd on

Connect to the Beyonwiz using C<telntt>.

When you see the C<#> command prompt, type

    rm /tmp/config/rc.localcopy /tmp/mnt/idehdd/telnetd
    exit

Then restart the Beyonwiz.

=head1 PREREQUSITES

Uses packages 
L<C<Beyonwiz::Hack::Utils>|Beyonwiz::Hack::Utils>.

=head1 BUGS

This firmware hack will not work on a DP-H1 (nothing bad will
happen to the DP-H1, you just won't be able to enable the hacks),
but if you do install it,
it's not straight-forward to remove.

B<Using I<bw_patcher> (or any other method) to create a modified
version of the firmware for any Beyonwiz model can result in a
firmware package that can cause the Beyonwiz firmware to fail
completely.>

=cut

use strict;
use warnings;

use Beyonwiz::Hack::Utils qw(
	findMatchingPath findNewFile
        patchFile addFile
    );
    
# System init file to patch
my $sysfile  = 'etc/rc.sysinit';

# String to match on
my $match    = '# rc\.local';

# After string? (or before it)
my $after    = 0;

# Commands to patch in
my $patch    = <<'EOF';
	if [ ! -x /etc/rc.localcopy ]; then
		rm -f "${CONFIG_DIR}/rc.local"
		cp /etc/rc.localcopy "${CONFIG_DIR}/rc.local"
	fi
EOF

# Location of rc.local file to be copied into /tm/pconfig
my $rc_local_file = 'etc/rc.localcopy';

# Make it executable?
my $rc_local_exec = 1;

# The contents of the rc.local file to be installed
my $rc_local      = <<'EOF';
#!/bin/sh

# An example rc.local to use with the bwhack hack enabler/disabler

HACKS='dim telnetd wizremote httproot'
SHOWHACKON=yes
SHOWHACKOFF=no

# Announce the presence of the rc.local
micomparam -q -t rc.local

# Wait for HDD to be mounted...
while [ ! -f /tmp/mnt/idehdd/.super ]; do sleep 1; done

for hack in $HACKS; do
    if [ -f /tmp/mnt/idehdd/$hack ]; then
	if [ $SHOWHACKON = yes ]; then micomparam -q -t $hack; fi
	case $hack in
	    telnetd)
		telnetd -l /bin/sh &
		;;
	    wizremote)
		(cd /tmp/mnt/idehdd/wizremote; ./wizremote > /dev/null &)
		;;
	    httproot)
		ln -s / /tmp/mnt/root
		;;
	    dim)
		# Tone down the display
		micomparam -q -r 500101
		;;
	esac
   else
	if [ $SHOWHACKOFF = yes ]; then micomparam -q -t $hack; fi
	case $hack in
	    telnetd)
		;;
	    wizremote)
		;;
	    httproot)
		;;
	    dim)
		;;
	esac
   fi
done

exit 0
EOF

sub hack($$) {
    my ($flash_dir, $root_dir) = @_;
    print "Patching in USB Hack support hack on $root_dir\n";

    my @sysinit = findMatchingPath($root_dir, $sysfile);

    die "Can't find $sysfile in $root_dir\n"
	if(!@sysinit);
    die "Found too many copies of $sysfile in $root_dir\n"
	if(@sysinit > 1);

    my $patches = patchFile($sysinit[0], $match, $patch, $after);
    die "Patch applied $patches times: should only be applied once!\n"
	if($patches != 1);

    my @rc_local = findNewFile($root_dir, $rc_local_file, $rc_local_exec);

    die "Can't find directory for $rc_local_file in $root_dir\n"
	if(!@rc_local);
    die "Found too many copies of $rc_local_file in $root_dir\n"
	if(@rc_local > 1);

    addFile($rc_local[0], $rc_local, $rc_local_exec);
}

1;

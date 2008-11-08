package Beyonwiz::Hack::BwhackSupport;

=head1 NAME

    Beyonwiz::Hack::BwhackSupport;

=head1 SYNOPSIS

A module to use as an argument to use with L< C<bw_patcher>|bw_patcher/ >.
It modifies the firmware to start a user-selectable set of hacks
that can be enabled/disabled using L< C<bwhack>|bwhack/ >.

B<Not suitable for use on a Beyonwiz DP-H1>. See L</BUGS>.

B<Not designed for use in combination with
L<C<Beyonwiz::Hack::USBHackSupport>|Beyonwiz::Hack::USBHackSupport>>.
However, the C<usb> hack that can be enabled through this
firmware patch contains all the functionality of
L<C<Beyonwiz::Hack::USBHackSupport>|Beyonwiz::Hack::USBHackSupport>.

The hacks available for enabling (default is all disabled) are,
in execution order:

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

This hack is not available on firmware versions 01.05.271 (beta) and later.
See L< C<bwhack>|bwhack/ > for details.

=item usb

Enable the use of hacks loaded from a USB drive or memory stick.
See L<C<Beyonwiz::Hack::USBHackSupport>|Beyonwiz::Hack::USBHackSupport>
for details.

=back

The installation process modifies the Beyonwiz firmware startup script
C</etc/rc.sysinit> to copy the added
firmware file C</flash/opt/rc.local> and C</flash/opt/usb.local>
into C</tmp/config>
each time the Beyonwiz starts.
C</tmp/config/rc.local> and C</tmp/config/usb.local> are also copied into,
and restored from,
non-volatile storage each time the Beyonwiz restarts.
C</etc/rc.sysinit> runs after this copy, so modifications to
C</tmp/config/rc.local> will be overwritten each time the
Beyonwiz starts (and before C</tmp/config/rc.local> has been run).
However, this means that even if you install an unmodified firmware package
on the beyonwiz, the patch will still be active, because running
C</tmp/config/rc.local> is part of normal firmware startup.

If the C<usb> hack is enabled by L< C<bwhack>|bwhack/ >,
C</tmp/config/usb.local>
is run from C</tmp/config/rc.local> to implement the ability
to run hacks from a USB drive (or memory card on an S1 or P1).
See L<C<Beyonwiz::Hack::USBHackSupport>|Beyonwiz::Hack::USBHackSupport>
for details.

The effect of this hack will I<not> be undone if you load
unmodified firmware onto the Beyonwiz.

=head1 DISABLING THE HACK

If the Beyonwiz is not running an unmodified firmware package,
download unmodified firmware into the Beyonwiz and
restart.

Then, either:

=over 4

=item 1

Enable only the C<telnet> hack using L< C<bwhack>|bwhack/ >
(installing unmodified firmware has not disabled the hacks):

    bwhack.pl --host=my.BW.IP.addr all off
    bwhack.pl --host=my.BW.IP.addr telnetd on

=item 2

Connect to the Beyonwiz using C<telnet>.

=item 3

When you see the C<#> command prompt, type

    rm /tmp/config/rc.local /tmp/config/usb.local /tmp/mnt/idehdd/telnetd
    exit

=back

or:

=over 4

=item 1

If they're not enabled already, enable USB hacks by running:

    bwhack.pl --host=my.BW.IP.addr usb on

then restarting the Beyonwiz.

=item 2

Then use the
L<C<S99removehacks>|Beyonwiz::Hack::USBHackSupport/item_S99removehacks>
in L<C<Beyonwiz::Hack::USBHackSupport>|Beyonwiz::Hack::USBHackSupport>
my copying it into C<beyonwiz/etc/init.d> on a USB stick or memory card,
connecting it to the Beyonwiz, and restart it. C<S99removehacks> will
remove all the files installed by this installer.

=back

Then restart the Beyonwiz (again, if you used the c<usb> hack).

=head1 FUNCTIONS

=over 4

=item C<< hack($flash_dir, $root_dir) >>

Called by L< C<bw_patcher>|bw_patcher/ > to perform the patch.

Inserts the lines:

    if [ -x /flash/opt/rc.local ]; then
        rm -f ${CONFIG_DIR}/rc.local
        cp /flash/opt/rc.local ${CONFIG_DIR}/rc.local
    fi
    if [ -x /flash/opt/usb.local ]; then
        rm -f ${CONFIG_DIR}/usb.local
        cp /flash/opt/usb.local ${CONFIG_DIR}/usb.local
    fi

into the file that will be C</etc/rc.sysinit>, the system startup script,
on the Beyonwiz.
The line will be inserted just before the comment line:

    # rc.local

It also adds the new files C</flash/opt/rc.local>
and C</flash/opt/usb.local> to the firmware.
These files are copied into place in <C/tmp/config>
to implement the hack.

=item C<< hackTag() >>

Returns C<bwhack> as the default suffix tag for the patch.

=item C<< printHack() >>

Prints the file that would be installed as
C</tmp/config/rc.local>
by this installer.

It can be run standalone as:

    perl -MBeyonwiz::Hack::USBHackSupport -e "Beyonwiz::Hack::USBHackSupport::printHack()"

You can similarly print the file that would be installed as
C</tmp/config/usb.local>
by running:

perl -MBeyonwiz::Hack::USBHackSupport -e "Beyonwiz::Hack::USBHackSupport::printHack()"

=back

=head1 PREREQUSITES

Uses packages
C<File::Spec::Functions>,
C<File::Path>,
L<C<Beyonwiz::Hack::USBHackSupport>|Beyonwiz::Hack::USBHackSupport>
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

This firmware hack will not work on a DP-H1 (nothing bad will
happen to the DP-H1, you just won't be able to enable the hacks),
but if you do install it,
it's not straight-forward to remove.

The hack names are displayed on the front panel as they execute.
Sometimes the last name will remain on the display until the
Beyonwiz overwrites it.
Changing channels will restore the dieplay to normal.

=cut

use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use File::Path 'mkpath';
use Beyonwiz::Hack::Utils qw(
	findMatchingPath makeMatchingDirectoryPath findNewFile
        patchFile addFile
    );
use Beyonwiz::Hack::USBHackSupport;
   
sub hackTag() {
    return 'bwhack';
}

# System init file to patch
my $sysfile  = 'etc/rc.sysinit';

# String to match on
my $match    = '# rc\.local';

# After string? (or before it)
my $after    = 0;

# Commands to patch in
my $patch    = <<'EOF';
	if [ -x /flash/opt/rc.local ]; then
		rm -f ${CONFIG_DIR}/rc.local
		cp /flash/opt/rc.local ${CONFIG_DIR}/rc.local
	fi
	if [ -x /flash/opt/usb.local ]; then
		rm -f ${CONFIG_DIR}/usb.local
		cp /flash/opt/usb.local ${CONFIG_DIR}/usb.local
	fi
EOF

# Location of rc.local file to be copied into /tmp/config
my $rc_local_dir = 'opt';
my $rc_local_file = catfile($rc_local_dir, 'rc.local');

# Make it executable?
my $rc_local_exec = 1;

# Location of usb.local file to be copied into /tmp/config
# to run USB device hacks
my $usb_local_dir = 'opt';
my $usb_local_file = catfile($usb_local_dir, 'usb.local');

# Make it executable?
my $usb_local_exec = 1;

# The contents of the rc.local file to be installed
my $rc_local      = <<'EOF';
#!/bin/sh

# An example rc.local to use with the bwhack hack enabler/disabler

HACKS='dim telnetd wizremote httproot usb'
export SHOWHACKON=yes
export SHOWHACKOFF=no

# Announce the presence of the rc.local
micomparam -q -t rc.local

# Wait for HDD to be mounted...
while [ ! -f /tmp/mnt/idehdd/.super ]; do sleep 1; done

for hack in $HACKS; do
    if [ -f /tmp/mnt/idehdd/$hack ]; then
	if [ "$SHOWHACKON" = yes ]; then micomparam -q -t $hack; fi
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
	    usb)
		# Run the USB hacks script
		if [ -r /tmp/config/usb.local ]; then
		    sh /tmp/config/usb.local
		fi
	esac
   else
	if [ "$SHOWHACKOFF" = yes ]; then micomparam -q -t $hack; fi
	case $hack in
	    telnetd)
		;;
	    wizremote)
		;;
	    httproot)
		;;
	    dim)
		;;
	    usb)
		;;
	esac
   fi
done

exit 0
EOF

sub printHack() {
    binmode STDOUT;
    $rc_local =~ s/\015\012/\012/g;
    print STDOUT $rc_local;
}

sub hack($$) {
    my ($flash_dir, $root_dir) = @_;
    print "Patching in USB Hack support hack on $root_dir\n";

    my @sysinit = findMatchingPath($root_dir, $sysfile);

    die "Can't find $sysfile in $root_dir\n"
	if(!@sysinit);
    die "Found too many copies of $sysfile in $root_dir\n"
	if(@sysinit > 1);

    my $patches = patchFile($sysinit[0], $match, $patch, $after);
    die "Patch applied $patches times: should be applied exactly once!\n"
	if($patches != 1);

    my @rc_local_dir = findMatchingPath($flash_dir, $rc_local_dir);
    if(!@rc_local_dir) {
	@rc_local_dir = makeMatchingDirectoryPath($flash_dir, $rc_local_dir);
	if(@rc_local_dir == 1) {
	    if(!-d $rc_local_dir[0]) {
		die "$rc_local_dir[0] exists already but isn't a directory\n"
		    if(-e _);
		print "Make new directory path: $rc_local_dir[0]\n";
		mkpath $rc_local_dir[0]
		    or die "Can't create $rc_local_dir[0] - $!\n";
	    }
	}
    }
    die "Found too many paths matching $rc_local_dir in $flash_dir\n"
	    if(@rc_local_dir > 1);

    my @rc_local = findNewFile($flash_dir, $rc_local_file, $rc_local_exec);

    die "Can't find directory for $rc_local_file in $flash_dir\n"
	if(!@rc_local);
    die "Found too many copies of $rc_local_file in $flash_dir\n"
	if(@rc_local > 1);

    addFile($rc_local[0], $rc_local, $rc_local_exec);

    Beyonwiz::Hack::USBHackSupport::addRcLocalFile($flash_dir,
					$usb_local_file, $usb_local_exec);
}

1;

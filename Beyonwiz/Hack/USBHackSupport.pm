package Beyonwiz::Hack::USBHackSupport;

=head1 NAME

Beyonwiz::Hack::USBHackSupport - hack to allow hacks to be run from a USB device

=head1 SYNOPSIS

    Beyonwiz::Hack::USBHackSupport;

A module to use as an argument to use with L< C<bw_patcher>|bw_patcher/>.
It modifies the firmware to start hack scripts that
are in the directory C<beyonwiz/etc/init.d> any USB device connected
at startup.
If no such USB device is connected at startup no hacks will be started.

Memory cards in the front slots on the DP-S1 count as connected USB devices,
so memory cards as well as USB thumb and hard drives can be used to enable
hacks this way.

B<Not designed for use in combination with
L<C<Beyonwiz::Hack::BwhackSupport>|Beyonwiz::Hack::BwhackSupport>>.
However, C<Beyonwiz::Hack::USBHackSupport>
offers all the functionality available through
L<C<Beyonwiz::Hack::BwhackSupport>|Beyonwiz::Hack::BwhackSupport>,
except L<C<httproot>|Beyonwiz::Hack::BwhackSupport/item_httproot>,
and unlike that patch, will work on the DP-H1.

The hacks available for enabling (default is all disabled) are:

=over 4

=item S00enablevfd

Enables display of progress through the hack startup on the
front panel VFD (Vacuum Fluorescent Display).

=item S01dimvfd

The front panel display is run in a dimmer mode (as it is when on standby).

=item S02telnet

Run I<telnetd> to allow login to the Beyonwiz using the I<telnet>
protocol.

=item S08recfixer

A version of tonymy01's I<Error loading media file> fixer.
Copies a C<stat> file from an existing recording into recordings
that are missing them, so that they become playable again.
Unlike tonymy01's version, which only repairs recordings
on the DP-S1 and DP-P1 internal drive, this version will also look
on any "registered for recording" drive on any Beyonwiz model
and repair recordings there.

=item S09wizremote

Starts Eric Fry's (efry) I<wizremote> server
(L<http://www.beyonwizsoftware.net/software-b28/wizremote>),
if it is installed in
/tmp/config. Otherwise has no effect.

=item S99removehacks

Removes the C</tmp/config/rc.local>
and C</tmp/config/usb.local> files from the Beyonwiz.
For this to be effective, unmodified Beyonwiz firmware must
be downloaded to the Beyonwiz first. See L<DISABLING THE HACK>.

This script can also be used in conjunction with the C<usb> hack
in L<C<Beyonwiz::Hack::BwhackSupport>|Beyonwiz::Hack::BwhackSupport>
to remove hacks installed by that installer.

=back

The patching process modifies the Beyonwiz firmware startup script
C</etc/rc.sysinit> to copy the added
firmware file C</flash/opt/rc.local> into C</tmp/config/rc.local>
each time the Beyonwiz starts.
C</tmp/config/rc.local> is also copied into, and restored from,
non-volatile storage each time the Beyonwiz restarts.
C</etc/rc.sysinit> runs after this copy, so modifications to
C</tmp/config/rc.local> will be overwritten each time the
Beyonwiz starts (and before C</tmp/config/rc.local> has been run).
However, this means that even if you install an unmodified firmware package
on the beyonwiz, the patch will still be active, because running
C</tmp/config/rc.local> is part of normal firmware startup.

The effect of this hack will I<not> be undone if you load
unmodified firmware onto the Beyonwiz.

=head1 DISABLING THE HACK

If the Beyonwiz is not running an unmodified firmware package,
download unmodified firmware into the Beyonwiz and
restart.

Remove the hacks by restarting the Beyonwiz with a USB device
that has (at least) C<S99removehacks> in C<beyonwiz/etc/init.d>.

Then restart the Beyonwiz.

=head1 PREPARING THE USB DEVICE OR MEMORY CARD

The USB device must be formatted as either FAT32 or NTFS.

Create the directories C<beyonwiz>, C<beyonwiz/etc> and
C<beyonwiz/etc/init.d> (or the equivalent C<beyonwiz\etc>, etc.
if you are using Windows).

Then copy the hack scripts you want to use from C<etc/init.d>
in this package into C<beyonwiz/etc/init.d> on the USB device
while it's connected to your PC (Mac, etc).

If the device prepared this way is connected to the Beyonwiz at startup,
the corresponding hacks will be started.

=head1 USING THE HACK USB DEVICE OR MEMORY CARD

To run/start the hacks that you've installed on the USB device
(or memory card),
simply plug the device into an appropriate port on the Beyonwiz,
and (re)start it.

If you've included the C<S00enablevfd> hack on the device when you
set it up, the progress of running the hack scripts will be shown on the
Beyonwiz front panel display.

If you've included C<S08recfixer> on the device, it will display
C<Fixed recording> on the front panel if any recordings were repaired
by the script.
It will also create a fake recording in the recording device's
C<recording> folder called C<Fixed_some_broken_recordings>
to indicate that repairs were made.
This recording will be unplayable, but it can be deleted.

=head1 FOR ADVANCED USERS

The scripts must be named starting with C<S> and two digits, and
the scripts on any single USB device will be run in numerical order.

You can temporarily disable a hack on a USB device simply by renaming
it not to start with C<S>.
It can be reactivated by renaming it to start with C<S>.

The startup code searches all USB devices connected to the Beyonwiz,
and runs scripts from any (and all) attached devices with the scripts in the
appropriate location.

The USB defices are searched in the following order:

=over 4

=item DP-S1

    Front panel memory card
    Front panel USB port
    Rear USB port

=item DP-P1 and DP-H1

    Lower rear USB port
    Upper rear USB port

=back

If two cards are inserted on the DP-S1 or DP-H1,
the search order is uncertain,
if it works at all.

If you want to create or modify scripts, B<you must use an
editor that respects and preserves Unix-style LF line endings>.
Many Windows editors do not do this.
In particular, WordPad will read the files correctly, but if you write them,
it will convert the line endings to the DOS CRLF convention, and they
will often fail to work on the Beyonwiz.
The CR character is I<not> treated as whitespace by the Beyonwiz shell.

You'll need to familiarise yourself with the limited Linux command set
available on the Beyonwiz, and the fact the command shell on
the Beyonwiz is much more limited than Linux C<bash> and similar.

Resources on L<http://www.OpenWiz.org/> may be useful.

You can test your scripts by copying them to a Windows Share
that the Beyonwiz can access, and mounting the share by
navigating to the share in the file player.
You can find where the share is mounted in the Beyonwiz file
system by running

    mount

=head1 FUNCTIONS

=over

=item C<< hack($flash_dir, $root_dir) >>

Called by L< C<bw_patcher>|bw_patcher/> to perform the patch.

Inserts the lines:

    if [ ! -x /flash/opt/rc.local ]; then
            rm -f "${CONFIG_DIR}/rc.local"
            cp /flash/opt/rc.local "${CONFIG_DIR}/rc.local"
    fi

into the file that will be C</etc/rc.sysinit>, the system startup script,
on the Beyonwiz.
The line will be inserted just before the comment line:

    # rc.local

It also adds the new file C</flash/opt/rc.local> to the firmware.
This file actually implements the hack.

=item C<< hackTag() >>

Returns C<usbhack> as the default suffix tag for the patch.

=item C<< printHack() >>

Prints the file that would be installed as
C</tmp/config/rc.local>
by this installer.

It can be run standalone as:

    perl -MBeyonwiz::Hack::USBHackSupport -e "Beyonwiz::Hack::USBHackSupport::printHack()"

=back

=head1 PREREQUSITES

Uses packages 
L<C<Beyonwiz::Hack::Utils>|Beyonwiz::Hack::Utils>,
C<File::Spec::Functions>
C<File::Path>;

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

Waits 4 seconds before searching for USB devices.
This may occasionally not be long enough.
If you expect patches to run, and they don't, try restarting
the Beyonwiz.
With the limited scripting facilities available, this bug is fifficult
to resolve.

=cut

use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use File::Path 'mkpath';
use Beyonwiz::Hack::Utils qw(
	findMatchingPath makeMatchingDirectoryPath findNewFile
        patchFile addFile
    );
    
sub hackTag() {
    return 'usbhack';
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
EOF

# Location of rc.local file to be copied into /tmp/config
my $rc_local_dir = 'opt';
my $rc_local_file = catfile($rc_local_dir, 'rc.local');

# Make it executable?
my $rc_local_exec = 1;

# The contents of the rc.local file to be installed
# This mechanism for activating hack is based on an idea from peteru
# on the Beyonwiz forum (http://www.beyonwiz.com.au/phpbb2/index.php),
# code written by tonymy01 on the same forum.

# For some reason the 'break' in the 'for typ' loop causes junk to be
# executed, so it's commented out.
# This doesn't affect the function of the script, but I don't know
# why it happens.
 
my $rc_local      = <<'EOF';
#!/bin/sh
MNTPT=/tmp/mnt/usb/tmp
log=/tmp/tweakbootlog

sleep 4

exec > $log 2>&1 <&-
date -u
mkdir $MNTPT

for dev in /dev/scsi/host*/bus*/target*/lun*/part*; do
    if [ -b $dev ]; then
	for typ in vfat ntfs; do
	    if mount -t $typ $dev $MNTPT; then
		echo mounted $dev
		if [ -d $MNTPT/beyonwiz/etc/init.d ]; then
		    echo beyonwiz/etc/init.d found, loading tweaks
		    for script in $MNTPT/beyonwiz/etc/init.d/S[0-9][0-9]*
		    do
			if [ -r "$script" ]; then
			    echo "loading tweak $script"
			    if [ "$SHOWHACKON" = yes ]; then
				msg=`basename $script`
				micomparam -q -t "$msg"
			    fi
			    . "$script"
			fi
		    done
		    cat $log >> $MNTPT/beyonwiz/etc/tweakbootlog.txt
		else
		    echo "no beyonwiz/etc/init.d tweaks appear"
		fi
		if umount $MNTPT 2>&1; then
		    :
		else
		    echo usb unmount failed
		    exit 1
		fi
		#break
	    fi
	done
    fi
done
rmdir $MNTPT
EOF

sub addRcLocalFile($$$) {
    my ($flash_dir, $rc_local_file, $rc_local_exec) = @_;

    my @rc_local = findNewFile($flash_dir, $rc_local_file, $rc_local_exec);

    die "Can't find directory for $rc_local_file in $flash_dir\n"
	if(!@rc_local);
    die "Found too many copies of $rc_local_file in $flash_dir\n"
	if(@rc_local > 1);

    addFile($rc_local[0], $rc_local, $rc_local_exec);
}

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
    die "Patch applied $patches times: should only be applied once!\n"
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

    addRcLocalFile($flash_dir, $rc_local_file, $rc_local_exec);
    my @rc_local = findNewFile($flash_dir, $rc_local_file, $rc_local_exec);

    die "Can't find directory for $rc_local_file in $root_dir\n"
	if(!@rc_local);
    die "Found too many copies of $rc_local_file in $root_dir\n"
	if(@rc_local > 1);

    addFile($rc_local[0], $rc_local, $rc_local_exec);
}

1;

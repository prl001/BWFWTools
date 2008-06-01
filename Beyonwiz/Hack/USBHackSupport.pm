package Beyonwiz::Hack::USBHackSupport;

=head1 NAME

    Beyonwiz::Hack::USBHackSupport;

=head1 SYNOPSIS

A module to use as an argument to use with L< C<bw_patcher>|bw_patcher/ >.
It modifies the firmware to start hack scripts that
are in the directory C<beyonwiz/etc/init.d> any USB device connected
at startup.
If no such USB device is connected at startup no hacks will be started.

Memory cards in the front slots on the DP-S1 count as connected USB devices,
so memory cards as well as USB thumb and hard drives can be used to enable
hacks this way.

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

Removes the C</tmp/config/rc.local> file from the Beyonwiz.
For this to be effective, unmodified Beyonwiz firmware must
be downloaded to the Beyonwiz first. See 

=back

The patching process modifies the Beyonwiz firmware startup script
C</etc/rc.sysinit> to copy the added
firmware file C</flash/hacks/rc.local> into C</tmp/config/rc.local>
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
and runs scripts from any (and all) attched devices with the scripts in the
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

If two cards are inserted on the DP-S1, the search order is uncertain, if it
works at all.

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

Called by L< C<bw_patcher>|bw_patcher/ > to perform the patch.

Inserts the lines:

    if [ ! -x /flash/hacks/rc.local ]; then
            rm -f "${CONFIG_DIR}/rc.local"
            cp /flash/hacks/rc.local "${CONFIG_DIR}/rc.local"
    fi

into the file that will be C</etc/rc.sysinit>, the system startup script,
on the Beyonwiz.
The line will be inserted just before the comment line:

    # rc.local

It also adds the new file C</flash/hacks/rc.local> to the firmware.
This file actually implements the hack.

=back

=head1 DISABLING THE HACK

If the Beyonwiz is not running an unmodified firmware package,
download unmodified firmware into the Beyonwiz and
restart.

Remove the hacks by restarting the Beyonwiz with a USB device
that has (at least) C<S99removehacks> in C<beyonwiz/etc/init.d>.

Then restart the Beyonwiz.

=head1 PREREQUSITES

Uses packages 
L<C<Beyonwiz::Hack::Utils>|Beyonwiz::Hack::Utils>
C<File::Spec::Functions>.

=head1 BUGS

Waits 4 seconds before searching for USB devices.
This may occasionally not be long enough.
If you expect patches to run, and they don't, try restarting
the Beyonwiz.
With the limited scripting facilities available, this bug is fifficult
to resolve.

B<Using I<bw_patcher> (or any other method) to create a modified
version of the firmware for any Beyonwiz model can result in a
firmware package that can cause the Beyonwiz firmware to fail
completely.>

=cut

use strict;
use warnings;

use File::Spec::Functions qw(catfile);
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
	if [ -x /flash/hacks/rc.local ]; then
		rm -f ${CONFIG_DIR}/rc.local
		cp /flash/hacks/rc.local ${CONFIG_DIR}/rc.local
	fi
EOF

# Location of rc.local file to be copied into /tm/pconfig
my $rc_local_dir = 'hacks';
my $rc_local_file = catfile($rc_local_dir, 'rc.local');

# Make it executable?
my $rc_local_exec = 1;

# The contents of the rc.local file to be installed
# This mechanism for activating hack is based on an idea from peteru
# on the Beyonwiz forum (http://www.beyonwiz.com.au/phpbb2/index.php),
# code written by tonymy01 on the same forum.

# For some reason the 'break' in the 'for typ' loop does nothing.
# This doesn't affect the function of the script, but I don't know
# why it happens.
 
my $rc_local      = <<'EOF';
#!/bin/sh
export MNTPT=/tmp/mnt/usb/tmp
log=/tmp/tweakbootlog
exec >> $log 2>&1 <&-

sleep 4

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
			    if [ /tmp/enablevfd ]; then
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
		break
	    fi
	done
    fi
done
rmdir $MNTPT
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

    my @hacksdir = findNewFile($flash_dir, $rc_local_dir, 1);
    die "Can't find directory for $rc_local_dir in $root_dir\n"
	if(!@hacksdir);
    die "Found too many copies of $rc_local_dir in $root_dir\n"
	if(@hacksdir > 1);
    die "Can't create $rc_local_dir in $root_dir: $!\n"
	if(!mkdir $hacksdir[0]);
    
    my @rc_local = findNewFile($flash_dir, $rc_local_file, $rc_local_exec);

    die "Can't find directory for $rc_local_file in $root_dir\n"
	if(!@rc_local);
    die "Found too many copies of $rc_local_file in $root_dir\n"
	if(@rc_local > 1);

    addFile($rc_local[0], $rc_local, $rc_local_exec);
}

1;

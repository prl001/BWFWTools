package Beyonwiz::Hack::Telnet;

=head1 NAME

    Beyonwiz::Hack::Telnet;

=head1 SYNOPSIS

A module to use as an argument to use with L< C<bw_patcher>|bw_patcher/ >
to patch Beyonwiz firmware to start C<telnetd> at startup to allow
D<telnet> connections to the Beyonwiz.

The effect of this hack will be undone if you load
unmodified firmware onto the Beyonwiz.

=head1 FUNCTIONS

=over

=item C<< hack($flash_dir, $root_dir) >>

Called by L< C<bw_patcher>|bw_patcher/ > to perform the patch.

Inserts the line:

    telnetd -l /bin/sh &

into the file that will be C</etc/rc.sysinit>, the system startup script,
on the Beyonwiz.
The line will be inserted just before the comment line:

    # rc.local

=back

=head1 DISABLING THE HACK

Simply download unmodified firmware into the Beyonwiz and
restart.

=head1 PREREQUSITES

Uses packages 
L<C<Beyonwiz::Hack::Utils>|Beyonwiz::Hack::Utils>.

=head1 BUGS

B<Using I<bw_patcher> (or any other method) to create a modified
version of the firmware for any Beyonwiz model can result in a
firmware package that can cause the Beyonwiz firmware to fail
completely.>

=cut

use strict;
use warnings;

use Beyonwiz::Hack::Utils qw(findMatchingPath patchFile);

# System init file to patch
my $sysfile  = 'etc/rc.sysinit';

# String to match on
my $match    = '# rc\.local';

# After string? (or before it)
my $after    = 0;

# Commands to patch in
my $patch    = <<'EOF';
	telnetd -l /bin/sh &
EOF

sub hack($$) {
    my ($flash_dir, $root_dir) = @_;
    print "Patching in Telnet hack on $root_dir\n";

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

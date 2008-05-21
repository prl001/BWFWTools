#!/usr/bin/perl

=pod

=head1 NAME

bwhack - remotely enable and disable Beyonwiz "hacks"


=head1 SYNOPSIS

    bwhack [-H host|--host=host] [-p port|--port=port]
	   [-v|--verbose] [-h|help] [ hack1 on hack2 off ...]


=head1 DESCRIPTION

Uses the presence and absence of files on the Beyonwiz HDD
to enable or disable various user extensions ("hacks") on the Beyonwiz
at startup time.

Must be used with a suitable C<rc.local> file installed
as executable in the Beyonwiz C</tmp/config>.
An example C<rc.local> is included in the
I<BWFWTools> package.

In order to get the file there in the first place,
Eric Fry's I<Telnet patch>
L<http://www.beyonwizsoftware.net/software-b28/telnet-firmware-patch>
can be used.
This only works on specific Beyonwiz firmware versions,
but once C<> is installed
on the Beyonwiz, it will not be removed
by firmware updates, only
by a Beyonwiz I<Factory Settings> reset.

Alternatively the C</etc/rc.sysinit> file in any
firmware distribution can be modified in a similar
way to the modification in I<Telnet patch>,
using L< C<unpack_wrp>|unpack_wrp/ >,
L< C<pack_wrp>|pack_wrp/ >
and a suitable editor.

=head1 ARGUMENTS

The main arguments allow the known hacks to be enabled (C<on>)
or disabled (C<off>).

If no "hack" arguments are given, prints which are enabled and which
are disbled.

The known hacks are

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

The options to I<bwhack> are:

=over 4

=item host

  --host=host
  -H host

Sets the host name or IP address of the Beyonwiz to connect to.

=item port

  --port=port
  -p port

Sets the IP port number of the Beyonwiz WizPnP/HTTP server
to connect to.
Must match the WizPnP port value set in C<<< SETUP>Network>WizPnP >>>
on the Beyonwiz.

=item verbose

  --verbose
  -v

Prints which hacks have been turned on or off.

=item help

  --help
  -h

Prints a summary of the command use.

=back

=head1 PREREQUSITES

Uses packages C<Getopt::Long>
and C<URI>,
C<LWP::Simple> and
C<HTTP::Request>.

=head1 BUGS

Requires a suitable startup procedure on the Beyonwiz
to work as intended.
The simplest way of adding one is to use an C<rc.local>
file like the one included in the I<BWFWTools> package installed
on the Beyonwiz in C</tmp/config>.

Using user extensions or hacks may make your Beyonwiz unable to
operate correctly, or even start.
If that happens, you may need to use the procedures in
B<NOTICE - How to recover from FW update failure>
L<http://www.beyonwiz.com.au/phpbb2/viewtopic.php?t=1298>
procedure on the Beyonwiz forum.
It's not known whether that procedure will fix all 
failure due to user modifications or "hacks".

=cut

use strict;
use warnings;

our $host = 'xerxes';
our $port = 49152;
our ($help, $verbose) = (0) x 2;

# List of known hacks. Should be the same as in HACKS in rc.local

my %hacks = (
    dim		=> 1,	# Dimmer display
    telnetd	=> 1,	# Run telnetd
    wizremote	=> 1,	# Run WizRemote server
    httproot	=> 1,	# Enable HTTP access to whole BW
);

use Getopt::Long qw(:config no_ignore_case bundling);
use URI;
use LWP::Simple qw($ua head);
use HTTP::Request;

sub Usage {
    warn "Usage: $0 [-H host|--host=host] [-p port|--port=port]\n",
	 "                   [-v|--verbose] [-h|--help]",
	 " [ hack1 on hack2 off ...]\n";
    warn 'Default host: ', $host, ' Default port: ', $port, "\n";
    die  'Known hacks: ', join(', ', sort keys %hacks), "\n";
}

GetOptions(
	'h|help',     \$help,
	'v|verbose+', \$verbose,
	'H|host=s',   \$host,
	'p|port=i',   \$port,
    ) or Usage;

$help and Usage;

sub hasHack($$) {
    my ($url, $hack) = @_;
    my $u = $url->clone;
    $u->path_segments($u->path_segments, $hack);
    my $response = head($u);
    return $response && $response->is_success;
}

sub switch($$$) {
    my ($url, $onoff, $hack) = @_;
    my @hacks;
    if($hack eq 'all') {
	@hacks = keys %hacks;
    } elsif(!$hacks{$hack}) {
	warn "Unknown hack $hack ignored\n";
	return;
    } else {
	push @hacks, $hack;
    }
    foreach my $h (@hacks) {
	my $u = $url->clone;
	my $data = "$h enabled\n";
	my $hasHack = hasHack($url, $h);
	$u->path_segments($u->path_segments, $h);
	if($onoff eq 'on' xor $hasHack) {
	    my $request;
	    if($onoff eq 'on') {
		$request = HTTP::Request->new(PUT => $u);
		$request->header(content_length => length $data);
		$request->content($data);
	    } else {
		$request = HTTP::Request->new(DELETE => $u);
	    }

	    my $response = $ua->request($request);

	    if($response->is_success
		or $onoff eq 'on'
		   and $response->status_line
			    eq '500 Server closed connection'
			     . ' without sending any data back'
		or $onoff eq 'off'
		    and $response->status_line
			    eq '500 DELETE Error') {
		print "$hack $onoff\n" if($verbose >= 1);
	    } else {
		    warn "$h $onoff: ", $response->status_line, " <$u>\n"
	    }
	} else {
	    print "$hack already ", ($hasHack ? 'on' : 'off'), "\n"
		if($verbose >= 1);
	}
    }
}

@ARGV % 2 == 0 or Usage;

my $url = URI->new('idehdd', 'http');
$url->scheme('http');
$url->host($host);
$url->port($port);

if(@ARGV) {
    while(my ($hack, $op) = splice @ARGV, 0, 2) {
	(switch($url, $op, $hack), next)  if($op eq 'on' || $op eq 'off');
	warn "Unknown operation $op for hack $hack; ignored\n";
    }
} else {
    foreach my $hack (sort keys %hacks) {
	print "$hack ", (hasHack($url, $hack) ? 'on' : 'off'), "\n";
    }
}

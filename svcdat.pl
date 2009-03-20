#!/usr/bin/perl

=pod

=head1 NAME

svcdat - print the contents of Beyonwiz C<svc.dat> (service scan configuration) files


=head1 SYNOPSIS

    svcdat svc.dat_files...

=head1 DESCRIPTION

Prints or dumps the tables in Beyonwiz C<svc.dat> files.
Normal listing is of the decoded service table, channel table
and (assumed) tuner parameter table grouped by channel, then by service.
The columns marked as PMT PID and PCR PID have not been confirmed
as the PIDs for the service Program Map Table and Program Clock Reference.
The (presumed) tuner parameters are indicated as C<T1(...) T2(...)>
for the two tuners.

The option B<-d> does a hexadecimal dump of the tables as 16-bit
little-endian integers.
The columns are headed by the interpretation of the values.

=head1 PREREQUSITES

Uses package C<Getopt::Long>.

=head1 BUGS

There are parts of the C<svc.dat> file whose function is unknown.
The T1 and T2 parameters are believed to relate to the tuners,
but that's uncertain, and the meaning of the parameters is unknown.

=head1 ACKNOWLEDGEMENTS

Most of the C<svc.dat> interpretation was done by
efry (Eric Fry) and tonymy01 (Tony)
on the Australian Beyonwiz Forum
(L<http://www.beyonwiz.com.au/phpbb2/index.php>).

=cut

use strict;
use warnings;

use Getopt::Long;

Getopt::Long::Configure qw(no_ignore_case bundling);

my ($dump, $help);

sub Usage {
    die "Usage: $0 [-d|--dump] svc.dat_files...\n";
}

GetOptions(
	'h|help', \$help,
	'd|dump', \$dump,
    ) or Usage;

$help and Usage;

sub unpackTuners($$$) {
    my ($hdr, $buf, $off) = @_;
    my $tuners = [];
    $hdr->{ntuner} = unpack '@' . $off . 'v', $buf;
    $off += 2;
    foreach my $i (0..$hdr->{ntuner}-1) {
	my $tuner =  { };
	(
	    $tuner->{p1},
	    $tuner->{p2},
	    $tuner->{p3},
	) = unpack '@' . $off . 'C2 v', $buf;
	push @$tuners, $tuner;
	$off += 4;
    }
    $hdr->{tuners} = $tuners;
    return $off;
}

sub unpackChans($$$) {
    my ($hdr, $buf, $off) = @_;
    my $chans = [];
    $hdr->{nchan} = unpack '@' . $off . 'v', $buf;
    $off += 34;
    foreach my $i (0..$hdr->{nchan}-1) {
	my $chan =  { };
	(
	    $chan->{chan},
	    $chan->{bw},
	    $chan->{freq},
	    $chan->{onid},
	    $chan->{tsid},
	) = unpack '@' . $off . 'C2 x2 V v2', $buf;
	push @$chans, $chan;
	$off += 12;
    }
    $hdr->{chans} = $chans;
    return $off;
}

sub unpackScvs($$$) {
    my ($hdr, $buf, $off) = @_;
    my $svcs = [];
    foreach my $i (0..$hdr->{nsvc}-1) {
	my $svc =  { };
	(
	    $svc->{radio},
	    $svc->{valid},
	    $svc->{chanIndex},
	    $svc->{svcId},
	    $svc->{pmtPID},
	    $svc->{videoPID},
	    $svc->{audioPID},
	    $svc->{pcrPID},
	    $svc->{svcNameIndex},
	    $svc->{chanNameIndex},
	    $svc->{tuner1},
	    $svc->{tuner2},
	    $svc->{lcn},
	) = unpack '@' . $off . 'v8 x4 v x2 v x2 v3', $buf;
	if($svc->{audioPID} & 0x8000) {
	    $svc->{audioPID} &= ~0x8000;
	    $svc->{AC3} = 1;
	} else {
	    $svc->{AC3} = 0;
	}
	push @$svcs, $svc;
	$off += 36;
    }
    $hdr->{svcs} = $svcs;
    return $off;
}

# Read and unpack the .wrp file header from the current
# file handle read location
# Return a hash of its interpreted values, or undef on failure.

sub readSvcFilehandle($) {
    my ($hdr) = @_;
    my $buf;
    my $off = 0;

    while(my $nread = sysread $hdr->{fileHandle}, $buf, 1024, $off) {
	$off += $nread;
    }
    return $buf;
}

sub decodeSvcFile($) {
    my ($buf) = @_;
    my $hdr = {};
    my $off = 0;

    (
	$hdr->{nsvc},
	$hdr->{svcNameLen},
	$hdr->{chanNameLen}
    ) = unpack '@48 v @54 V2', $buf;

    $hdr->{svcNames} = unpack '@62 a'.$hdr->{svcNameLen}, $buf;
    $off = 62 + $hdr->{svcNameLen};
    $hdr->{chanNames} = unpack '@' . $off . 'a'.$hdr->{chanNameLen}, $buf;
    $off += $hdr->{chanNameLen} + 10;

    $off = unpackTuners($hdr, $buf, $off);
    $off = unpackScvs($hdr, $buf, $off);
    $off += 6;
    $off = unpackChans($hdr, $buf, $off);

    return $hdr;
}

# Open the file, and read and intepret the .wrp header.
# Return a hash of its interpreted values, or undef on failure.

sub readSvcFile($) {
    my ($fn) = @_;
    my $hdr = {};
    open WRP, $fn or return undef;

    $hdr->{fileHandle} = \*WRP;
    return readSvcFilehandle($hdr);
}

sub getName($$) {
    my ($buf, $offset) = @_;
    return unpack '@' . $offset . 'Z*', $buf;
}

sub printTuner($$$$) {
    my ($fh, $name, $hdr, $tunerIndex) = @_;
    my $tuner = $hdr->{tuners}[$tunerIndex];
    printf " %s(%2d %2d)",
	$name,
	(defined($tuner->{p1}) ? $tuner->{p1} : -1),
	(defined($tuner->{p2}) ? $tuner->{p2} : -1);
}

# Print the contents of the header $hdr on standard output

sub printHdr($) {
    my ($hdr) = @_;

    my @svcs;
    foreach my $svc (@{$hdr->{svcs}}) {
	push @svcs, $svc if($svc->{valid});
    }

    @svcs = sort {
				    $hdr->{chans}[$a->{chanIndex}]
				<=>
				    $hdr->{chans}[$b->{chanIndex}]
			    ||
				    $a->{lcn}
				<=>
				    $b->{lcn}
			} @svcs;
    my $lastChanName = '';
    for(my $i = 0; $i < @svcs; $i++) {
 	my $svc = $svcs[$i];
	if($svc->{valid}) {
	    my $chanName = getName($hdr->{chanNames}, $svc->{chanNameIndex});
	    my $svcName = getName($hdr->{svcNames}, $svc->{svcNameIndex});
	    if($lastChanName ne $chanName) {
		print "\n" if($i);
		my $chan = $hdr->{chans}[$svc->{chanIndex}];
		printf "%2x %7.3f MHz %3d MHz BW onid: %5u tsid: %5u %s\n",
		    $chan->{chan}, $chan->{freq}/1000, $chan->{bw},
		    $chan->{onid}, $chan->{tsid},
		    $chanName;
		print "            PMT   PCR video   audio\n";
		print "LCN svcId   PID   PID   PID   PID\n";
		print "-------------------------------------------\n";
		$lastChanName = $chanName;
	    }
	    printf "%3u %5u %5u %5u %5u %5u %-3s %-5s",
		    $svc->{lcn},
		    $svc->{svcId},
		    $svc->{pmtPID}, $svc->{pcrPID},
		    $svc->{videoPID}, $svc->{audioPID},
		    $svc->{AC3} ? 'AC3' : '',
		    $svc->{radio} ? 'Radio' : 'TV';
	    printTuner(\*STDOUT, 'T1', $hdr, $svc->{tuner1});
	    printTuner(\*STDOUT, 'T2', $hdr, $svc->{tuner2});
	    printf " %s\n",
		    $svcName
	}
    }
}

sub dumpHdr($$) {
    my ($hdr, $buf) = @_;

    print "                    PMT       video audio   PCR tunerParams   svc        chan                     lcn      \n";
    print "radio valid chanX   PID svcId   PID   PID   PID CONST CONST nameX CONST nameX CONST    t1    t2   lcn xxxxx\n";
    my $off = 62 + $hdr->{svcNameLen} + $hdr->{chanNameLen}
            + 12 + $hdr->{ntuner} * 4;
    for(my $i = 0; $i < $hdr->{nsvc}; $i++) {
 	my $svc = $hdr->{svcs}[$i];
	my $svcName = getName($hdr->{svcNames}, $svc->{svcNameIndex});
	my @vals = unpack '@' . $off . 'v18', $buf;
	print ' ', join('  ', map( {sprintf "%04x", $_} @vals), $svcName), "\n";
	print join(' ', map {sprintf "%5d", $_} @vals), "\n";
	$off += 36;
    }

    $off += 40;
    print "\n";
    print " chan\n";
    print "   BW CONST  freq (kHz)  onit  tsid\n";
    for(my $i = 0; $i < $hdr->{nchan}; $i++) {
	my @vals = unpack '@' . $off . 'v6', $buf;
	last if(($vals[0] & 0xff) == 0xff);
	print ' ', join('  ', map( {sprintf "%04x", $_} @vals)), "\n";
	print join(' ', map {sprintf "%5d", $_} @vals), "\n";
	$off += 12;
    }

    $off = 62 + $hdr->{svcNameLen} + $hdr->{chanNameLen} + 12;
    print "\n";
    print "  p1/p2    p3\n";
    for(my $i = 0; $i < $hdr->{ntuner}; $i++) {
	my @vals = unpack '@' . $off . 'v2', $buf;
	last if(($vals[0] & 0xff) == 0xff);
	printf "%2d %s\n", $i, join('  ', map( {sprintf "%04x", $_} @vals));
	print '  ', join(' ', map {sprintf "%5d", $_} @vals), "\n";
	$off += 4;
    }
}

# Loop through the arguments, printing the headers.

foreach my $fn (@ARGV) {
    my $buf = readSvcFile($fn);
    if(defined $buf) {
	my $hdr = decodeSvcFile($buf);
	if($hdr) {
	    print "$fn:\n";
	    if($dump) {
		dumpHdr($hdr, $buf);
	    } else {
		printHdr($hdr);
	    }
	} else {
	    warn "$fn: $!\n";
	}
    }
}

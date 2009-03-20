#!/usr/bin/perl

=pod

=head1 NAME

lastplaypoint - print the Beyonwiz resume marker file lastplaypoint.dat


=head1 SYNOPSIS

    dump_strings lastplaypoint.dat_files...

=head1 DESCRIPTION

Prints the contents of the files in the format of
the C</tmp/config/lastplaypoint.dat> file on Beyonwiz PVRs.

The output is one line for each valid resume point
in the media file or recording,
the resume offset in decimal,
followed by the name of the file.

It's not clear what the offset units are in the file.
They appear to be approx 0.5 sec.

=head1 BUGS

The offset units are unknown.

=cut

while(my $fn = shift) {
    print "$fn:\n";
    if(open F, '<', $fn) {
	my ($buf, $nread);
	while($nread = sysread F, $buf, 1028) {
	    last if($nread != 1028);
	    my ($name, $offset) = unpack 'Z1024 V', $buf;
	    printf "%8d %s\n", $offset, $name if($offset && $name ne '');
	}
	warn "$0: $fn - $!\n" if(!defined $nread);
    } else {
	warn "$0: Can't open $fn - $!\n";
    }
}

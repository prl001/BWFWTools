package Beyonwiz::SystemId;

=head1 NAME

Beyonwiz::SystemId - Perl package of useful functions for Beyonwiz SystemIds and model names

=head1 SYNOPSIS

    use Beyonwiz::SystemId;
    
or

    use Beyonwiz::SystemId qw(
			normaliseModel
			flashSizefromModel
			flashSizefromSysIdArray
			flashSizefromSysIdStr
			modelFromSysIdArray
			parseSysIdStr
			modelFromSysIdStr
		);

=head1 FUNCTIONS

=over

=item C<normaliseModel($name);>

Convert the Beyonwiz model name in either of C<DP-S1> or C<DPS1>
forms to the C<DP-S1> form.

Returns the normalised model name, or C<undef> if the name is not recognised.

Also allows C<S>, C<P> and C<H> to be used as arguments for
C<DP-S1>, C<DP-P1> and C<DP-H1>,
but this usage is deprecated.

=item C<parseSysIdStr($id)>

Given a 16 hexadecimal digit
string, convert it into a reference
to a 4-entry array of 16-bit integers.

The 4-digit groups may be separated either by spaces or C<->.

The following parse to the sysid array for the DP-S1
(C<[ 0x0808, 0x0000, 0x0E20, 0xBE3E ]>:

    0808 0000 0E20 BE3E
    0808-0000-0e20-Be3e
    080800000e20BE3E

Returns C<undef> if the string is incorrectly formatted.

=item C<modelFromSysIdArray($id)>

Returns the normalised name for a Beyonwiz device
given a 4-entry sysid array (as returned from
C<L<parseSysIdStr($id)>>).

Returns C<undef> if the sysid is not recognised.

=item C<modelFromSysIdStr($id)>

Returns the normalised name for a Beyonwiz device
given a sysid string
(in one of the forms recognised by
C<L<parseSysIdStr($id)>>).

Returns C<undef> if the sysid is not recognised.

=item C<flashSizefromModel($name)>

Returns the flash memory size in bytes for the given model
number named in normalised form.

Returns C<undef> for unrecognised model names.

=item C<flashSizefromSysIdArray($id)>

Returns the flash memory size in bytes for the
model sysid given as an array of 4 16-bit integers.

Returns C<undef> for unrecognised model sysids.

=item C<flashSizefromSysIdStr($id)>

Returns the flash memory size in bytes for the
model sysid given as a hexadecimal string.

Returns C<undef> for unrecognised model sysids.


=cut

use strict;

use Exporter;

@Beyonwiz::SystemId::ISA = qw(Exporter);
@Beyonwiz::SystemId::EXPORT_OK = qw(
			normaliseModel
			flashSizefromModel
			flashSizefromSysIdArray
			flashSizefromSysIdStr
			modelFromSysIdArray
			parseSysIdStr
			modelFromSysIdStr
		);

# The DP-P2 flash is 8MB, but 4 x 128-kB segments are reserved for other uses
use constant MAX_FLASH_P2    => 16 * 1024*1024 - 4 * 128 * 1024;

# On other models, flash is 8MB,
# and 5 x 64-kB segments are reserved for other uses
use constant MAX_FLASH_OTHER =>  8 * 1024*1024 - 5 * 64 * 1024;

my @machCodeMap = (
    # Australian terrestrial models

    [ [ 0x0808, 0x0000, 0x0E20, 0xBE3E ], 'DP-S1' ],
    [ [ 0x0808, 0x0000, 0x0A22, 0xBE3C ], 'DP-P1' ],
    [ [ 0x0908, 0x0000, 0x0A22, 0x9E3C ], 'DP-P2' ],
    [ [ 0x0408, 0x0000, 0x0022, 0x7E3C ], 'DP-H1' ],
    [ [ 0x0808, 0x0000, 0x0002, 0x9E3C ], 'DP-Lite' ],
    [ [ 0x0808, 0x0002, 0x0A22, 0x9E3C ], 'FV-L1' ],

    # Finnish terrestrial models

    [ [ 0x0808, 0x0000, 0x0E20, 0xBE3E ], 'FT-P1' ],     # not confirmed
    [ [ 0x0808, 0x0000, 0x0A22, 0xBE3C ], 'FT-H1' ],     # not confirmed 

    # Finnish cable models

    [ [ 0x0808, 0x0000, 0x0A22, 0xBE3C ], 'FC-P1' ],     # not confirmed
    [ [ 0x0408, 0x0000, 0x0022, 0x7E3C ], 'FC-H1' ],     # not confirmed 
);

my %modelMap = (
    'DPS1'   => 'DP-S1',
    'DPP1'   => 'DP-P1',
    'DPP2'   => 'DP-P2',
    'DPH1'   => 'DP-H1',
    'DPLite' => 'DP-Lite',
    'FVL1'   => 'FV-L1',
    'S'      => 'DP-S1',
    'P'      => 'DP-P1',
    'H'      => 'DP-H1',

    # Finnish terrestrial models

    'FTP1'   => 'FT-P1',     # not confirmed
    'FTH1'   => 'FT-H1',     # not confirmed 

    # Finnish cable models

    'FCP1'   => 'FC-P1',     # not confirmed
    'FCH1'   => 'FC-H1',     # not confirmed 
);

my %flashMap = (
    'DP-S1'   => MAX_FLASH_OTHER,
    'DP-P1'   => MAX_FLASH_OTHER,
    'DP-P2'   => MAX_FLASH_P2,
    'DP-H1'   => MAX_FLASH_OTHER,
    'FV-L1'   => MAX_FLASH_OTHER,
    'DP-Lite' => MAX_FLASH_OTHER,

    # Finnish terrestrial models

    'FT-P1'   => MAX_FLASH_OTHER,     # not confirmed
    'FT-H1'   => MAX_FLASH_OTHER,     # not confirmed 

    # Finnish cable models

    'FC-P1'   => MAX_FLASH_OTHER,     # not confirmed
    'FC-H1'   => MAX_FLASH_OTHER,     # not confirmed 
);

sub normaliseModel($) {
    my ($name) = @_;
    $name =~ s/^(..)-(.+)$/$1$2/;
    return $modelMap{$name};
}

sub modelFromSysIdArray($) {
    my ($id) = @_;
    if(@$id == 4) {
	foreach my $idMap (@machCodeMap) {
	    my $match;
	    foreach my $i (0..3) {
	        last if($id->[$i] != $idMap->[0][$i]);
		$match++;
	    }
	    return $idMap->[1] if($match == 4);
	}
    }
    return undef;
}

sub parseSysIdStr($) {
    my ($id) = @_;
    return [ map { hex($_) }
		$id =~ m/^(?:([:xdigit}]{4})[ \-]?){3}([:xdigit}]{4})$/
	   ];
}

sub modelFromSysIdStr($) {
    my ($id) = @_;
    return modelFromSysIdArray(parseSysIdStr($id));
}

sub flashSizefromModel($) {
    my ($name) = @_;
    return $flashMap{normaliseModel($name)};
}

sub flashSizefromSysIdArray($) {
    my ($id) = @_;
    my $name = modelFromSysIdArray($id);
    return defined($name) ? flashSizefromModel($name) : undef;
}

sub flashSizefromSysIdStr($) {
    my ($id) = @_;
    my $name = modelFromSysIdStr($id);
    return defined($name) ? flashSizefromModel($name) : undef;
}


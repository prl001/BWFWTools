package Beyonwiz::Kernel;

=head1 NAME

Beyonwiz::Kernel - Perl package of support routines for uncompressed Beyonwiz kernel images.

=head1 SYNOPSIS

    use Beyonwiz::Kernel;
    
or

    use Beyonwiz::Kernel qw(
		    BASE
		    sym_val
		    check_magics
		    read_or_die
		    write_or_die
		    get_words
		    get_words_sym
		    get_str
		);

=cut

use strict;

@Beyonwiz::Kernel::ISA = qw(Exporter);
@Beyonwiz::Kernel::EXPORT_OK = qw(
		    BASE
		    sym_val
		    check_sym
		    check_magics
		    read_or_die
		    write_or_die
		    get_words
		    get_words_sym
		    get_str
		);

use POSIX;

=head1 CONSTANTS

=over

=item C<BASE>

The memory address corresponding to the start of the kernel image file.
For Beyonwiz DP series PVRs, 0x90090000.
This is 64kB higher than the start of memory at 0x90080000.

=back

=cut

use constant BASE	=> 0x90090000;

# Warn, but don't die if these symbols are missing

my %optional_symbols = (
    __start___ksymtab	=> 1,
    __stop___ksymtab	=> 1,
);

my %kern_locs = (
    DRAM_BASE => [
	[
	    {
		loc => 0x00000038,
		magics => [
		     [ 0x90090028, 0xe59f1008 ],
		     # Checks that the value for DRAM_BASE
		     # is correct (0x90080000)
		     [ 0x90090038, 0x90080000 ],
		 ]
	    },
	],
    ],
    _stext => [
	[   # before 01.05.261
	    {
		loc => 0x90090694,
		magics => [
		    [ 0x900905e0, 0xe59f20ac ],
		    # Checks that the value for _stext is correct (0x90090000)
		    [ 0x90090694, 0x90090000 ],
		 ]
	    },
	],
	[   # 01.05.269 and later
	    {
		loc => 0x90090690,
		magics => [
		    [ 0x900905dc, 0xe59f20ac ],
		    # Checks that the value for _stext is correct (0x90090000)
		    [ 0x90090690, 0x90090000 ],
		 ]
	    },
	],
    ],
    _text => [
	[   # before 01.05.261
	    {
		loc => 0x900920f8,
		magics => [
		    [ 0x90092058, 0xe59f3098 ],
		 ]
	    },
	],
	[   # 01.05.269 and later
	    {
		loc => 0x900920d8,
		magics => [
		    [ 0x90092038, 0xe59f3098 ],
		 ]
	    },
	],
    ],
    _etext => [
	[   # before 01.05.261
	    {
		loc => 0x90090690,
		magics => [
		    [ 0x900905d8, 0xe59f30b0 ],
		 ]
	    },
	    {
		loc => 0x900920fc,
		magics => [
		    [ 0x9009205c, 0xe59f2098 ],
		 ]
	    },
	],
	[   # 01.05.269 and later
	    {
		loc => 0x9009068c,
		magics => [
		    [ 0x900905d4, 0xe59f30b0 ],
		 ]
	    },
	    {
		loc => 0x900920dc,
		magics => [
		    [ 0x9009203c, 0xe59f2098 ],
		 ]
	    },
	],
    ],
    _edata => [
	[   # before 01.05.261
	    {
		loc => 0x90092100,
		magics => [
		    [ 0x90092068, 0xe59f3090 ],
		 ]
	    },
	],
	[   # 01.05.269 and later
	    {
		loc => 0x900920e0,
		magics => [
		    [ 0x90092048, 0xe59f3090 ],
		 ]
	    },
	],
    ],
    __bss_start => [
	[   # before 01.05.261
	    {
		loc => 0x90090074,
		magics => [
		    [ 0x900900c4, 0xe89321f4 ], # Actual reference instruction
		    [ 0x90090064, 0xe28fe020 ], # Additional context
		    [ 0x90090068, 0xe28af00c ],
		    [ 0x9009206c, 0xe59f2090 ],
		    [ 0x9009008c, 0xe51fe028 ],
		    [ 0x90090090, 0xee010f10 ],
		 ]
	    },
	],
	[   # 01.05.269 and later
	    {
		loc => 0x90090074,
		magics => [
		    [ 0x900900c4, 0xe89321f4 ], # Actual reference instruction
		    [ 0x90090064, 0xe28fe020 ], # Additional context
		    [ 0x90090068, 0xe28af00c ],
		    [ 0x9009204c, 0xe59f2090 ],
		    [ 0x9009008c, 0xe51fe028 ],
		    [ 0x90090090, 0xee010f10 ],
		 ]
	    },
	],
    ],
    _end => [
	[   # before 01.05.261
	    {
		loc => 0x90090078,
		magics => [
		    [ 0x900900c4, 0xe89321f4 ], # Actual reference instruction
		    [ 0x90090064, 0xe28fe020 ], # Additional context
		    [ 0x90090068, 0xe28af00c ],
		    [ 0x9009206c, 0xe59f2090 ],
		    [ 0x9009008c, 0xe51fe028 ],
		    [ 0x90090090, 0xee010f10 ],
		 ]
	    },
	    {
		loc => 0x90092104,
		magics => [
		    [ 0x9009206c, 0xe59f2090 ], # Actual reference instruction
		 ]
	    },
	],
	[   # 01.05.269 and later
	    {
		loc => 0x90090078,
		magics => [
		    [ 0x900900c4, 0xe89321f4 ], # Actual reference instruction
		    [ 0x90090064, 0xe28fe020 ], # Additional context
		    [ 0x90090068, 0xe28af00c ],
		    [ 0x9009204c, 0xe59f2090 ],
		    [ 0x9009008c, 0xe51fe028 ],
		    [ 0x90090090, 0xee010f10 ],
		 ]
	    },
	    {
		loc => 0x900920e4,
		magics => [
		    [ 0x9009204c, 0xe59f2090 ], # Actual reference instruction
		 ]
	    },
	],
    ],
    __start___ksymtab => [
	[
	    {
		loc => 0x90093d44,
		magics => [
		    [ 0x90093d24, 0xe59f2018 ],
		 ]
	    },
	],
    ],
    __stop___ksymtab => [
	[
	    {
		loc => 0x90093d40,
		magics => [
		    [ 0x90093d20, 0xe59f3018 ],
		 ]
	    },
	],
    ],
    arena => [
	[
	    {   # before 01.05.243
		loc => 0x90097e58,
		magics => [
		    [ 0x90097bd4, 0xe59f927c ],
		 ]
	    },
	],
	[
	    {   # 01.05.243 and before 01.05.269
		loc => 0x90097e54,
		magics => [
		    [ 0x90097bd0, 0xe59f927c ],
		 ]
	    },
	],
	[
	    {   # 01.05.269 and later
		loc => 0x90097dcc,
		magics => [
		    [ 0x90097b48, 0xe59f927c ],
		 ]
	    },
	],
	[
	    {   # 01.05.283 and later
		loc => 0x90097de8,
		magics => [
		    [ 0x90097b64, 0xe59f927c ],
		 ]
	    },
	],
    ],
);

my %matched_loc;

=head1 FUNCTIONS

=over

=item C<check_sym($sym)>

Looks up C<$sym> in an internal table, and returns true
if the corresponding symbol has been found.

=cut

sub check_sym($) {
    my ($sym) = @_;
    return defined $kern_locs{$sym}
	&& defined $matched_loc{$sym}
	&& defined $kern_locs{$sym}[$matched_loc{$sym}]
	&& defined $kern_locs{$sym}[$matched_loc{$sym}][0]
	&& defined $kern_locs{$sym}[$matched_loc{$sym}][0]{loc};
}

=item C<sym_val($sym)>

Looks up C<$sym> in an internal table, and returns the address of a word
in the kernel that contains the symbol value.
Fatal error if the symbol is not defined.

Recognised symbols are:

    DRAM_BASE         Start of RAM (0x90080000)
    _stext            Start of kernel code, or text segment (same as BASE)
    _text             Start of main kernel code after initialisation code
    _etext            End of kernel code, or text segment
    _edata            Start of initialised data segment
    __bss_start       Start of uninitialised data, or bss, segment
    _end              End of uninitialised data, or bss, segment, and end of kernel
    __start___ksymtab Start of the kernel module symbol table
    __stop___ksymtab  End of the kernel module symbol table
    rootROMFS         Start of the embedded ROMFS root file system (in initialised data segment)

=cut

sub sym_val($) {
    my ($sym) = @_;
    die "Kernel symbol $sym not defined\n"
	if(!check_sym($sym));
    return $kern_locs{$sym}[$matched_loc{$sym}][0]{loc};
}

=item C<get_words($fh, $addr, $n)>

In an array context, returns an array of C<$n> words (32-bit integers)
commencing at Beyonwiz memory address C<$addr> in the uncompressed
Beyonwiz kernel image referenced by the file handle reference C<$fh>.
In a scalar context, returns the first element of the array, so

    $val = get_words($fh, $addr, 1);

will work as expected.

The words will be translated from the kernel image's little-endian order
to the native order of the machine running the perl script.

=cut

sub get_words($$$) {
    my ($fh, $addr, $n) = @_;
    my $buf;
    sysseek $fh, $addr - BASE, SEEK_SET
	or die sprintf "Seek to fetch words 0x%08x failed $!\n", $addr;
    my $nbytes = $n * 4;
    my $nread = sysread $fh, $buf, $nbytes;
    die sprintf "Read of words at addr 0x%08x failed: %s\n", $addr, $!
	if(!defined $nread);
    die sprintf "Short read of words at addr 0x%08x read $nread bytes,"
	    . " should have been $nbytes bytes\n", $addr
	if($nread != $nbytes);
    return unpack "V$n", $buf;
}

=item C<get_words_sym($fh, $sym, $n)>

Looks up C<$sym> in an internal table, and uses the symbol's location
as the C<$addr> and returns the result of C<get_words($fh, $addr, $n)>.

Equivalent to (and implemented as)

    get_words($fh, sym_val($sym), $n);

Typical use is as

    get_words_sym($fh, 'symname', 1)

to return the value of the symbol.

=cut

sub get_words_sym($$$) {
    my ($fh, $sym, $n) = @_;
    die "Kernel symbol $sym not defined\n"
	if(!$kern_locs{$sym});
    return get_words($fh, $kern_locs{$sym}[$matched_loc{$sym}][0]{loc}, $n);
}

=item C<get_str($fh, $addr)>

Returns a a null-terminated ASCII string starting ar 
commencing at Beyonwiz memory address C<$addr> in the uncompressed
Beyonwiz kernel image referenced by the file handle reference C<$fh>.

The maximum string length that can be returned is 1024 bytes.
This probably should be a parameter, or made unlimited.

=cut

sub get_str($$) {
    my ($fh, $addr) = @_;
    my $buf;
    sysseek $fh, $addr - BASE, SEEK_SET
	or die sprintf "Seek to fetch string 0x%08x failed $!\n", $addr;
    sysread $fh, $buf, 1024
	or die sprintf "Read of string at addr 0x%08x failed $!\n", $addr;
    my $null = index $buf, "\0";
    return unpack "Z1024", $buf;
}

=item C<read_or_die($fn, $fh, $loc, $buf, $n, $die)>

Seek to C<$loc> in file handle reference C<$fh>, and read C<$n>
bytes into the reference C<$buf>. C<$fn> is the file name associated with
C<$fh>, and is only used for error messages.

Fatal error on I/O error, short read or end-of-file if C<$die> is true,
otherwise returns false on these conditions.

Returns true on success.

=cut

sub read_or_die($$$$$$) {
    my ($fn, $fh, $loc, $buf, $n, $die) = @_;
    if(!sysseek $fh, $loc, SEEK_SET) {
	die sprintf "Seek in file %s to location 0x%08x failed: %s\n",
		$fn, $loc, $!
	    if($die);
	return 0;
    }
    my $nread = sysread $fh, $$buf, $n;
    if(!defined $nread) {
	die sprintf "Read of file %s at location 0x%08x failed %s\n",
		$fn, $loc, $!
	    if($die);
	return 0;
    }
    if($nread == 0) {
	die sprintf "End of file in %s at file location 0x%08x\n",
		$fn, $loc
	    if($die);
	return 0;
    }
    if($nread != $n) {
	die sprintf "Short read of %s at file location 0x%08x"
			." read %d bytes, should have been %d bytes\n",
		$fn, $loc, $nread, $n
	    if($die);
	return 0;
    }
    return 1;
}

=item C<write_or_die($fn, $fh, $loc, $buf, $n, $die)>

Seek to C<$loc> in file handle reference C<$fh>, and write C<$n>
bytes into the file from reference C<$buf>.
C<$fn> is the file name associated with C<$fh>,
and is only used for error messages.

Fatal error on I/O error or short write if C<$die> is true,
otherwise returns false on these conditions.

Returns true on success.

=cut

sub write_or_die($$$$$$) {
    my ($fn, $fh, $loc, $buf, $n, $die) = @_;
    if(!sysseek $fh, $loc, SEEK_SET) {
	die sprintf "Seek in file %s to location 0x%08x failed: %s\n",
		$fn, $loc, $!
	    if($die);
	return 0;
    }
    my $nwrite = syswrite $fh, $$buf, $n;
    if(!defined $nwrite) {
	die sprintf "Write of file %s at location 0x%08x failed %s\n",
		$fn, $loc, $!
	    if($die);
	return 0;
    }
    if($nwrite != $n) {
	die sprintf "Short write of %s at file location 0x%08x"
			." read %d bytes, should have been %d bytes\n",
		$fn, $loc, $nwrite, $n
	    if($die);
	return 0;
    }
    return 1;
}

=item C<check_magics($kern_fn, $kern_fh)>

Checks context information in the internal symbol location table
(mostly the instructions that reference the pointers in the kernel that
contain the symbol values) to verify that the symbol locations
in the table are correct.

The kernel is  referenced by the file handle reference C<$fh>.
C<$fn> is the kernel file name, used only for error messages.

Also checks that

    get_words_sym($kern_fh, '_stext', 1) == BASE

To ensure that the kernel commences at the expected location.

Fatal error if the checks fail.

=cut

sub check_magics($$) {
    my ($kern_fn, $kern_fh) = @_;
    my @magics;
    my $errs = 0;
    while(my ($sym, $data) = each %kern_locs) {
	my $version;
	foreach my $ver (0..$#$data) {
	    my $ver_ok = 1;
	    foreach my $loc (@{$data->[$ver]}) {
		foreach my $magic (@{$loc->{magics}}) {
		    my $val = get_words($kern_fh, $magic->[0], 1);
		    $ver_ok = 0
			if($val != $magic->[1]);
		}
	    }
	    if($ver_ok) {
		$version = $ver;
		last;
	    }
	}
	if(defined $version) {
	    $matched_loc{$sym} = $version;
	} else {
	    foreach my $ver (0..$#$data) {
		foreach my $loc (@{$data->[$ver]}) {
		    foreach my $magic (@{$loc->{magics}}) {
			my $val = get_words($kern_fh, $magic->[0], 1);
			warn sprintf 'Context for %s'
				. ' - Expected 0x%08x at 0x%08x in %s:'
				. " got 0x%08x\n",
				$sym,
				$magic->[1], $magic->[0],
				$kern_fn, $val
			    if($magic->[1] != $val
			    && !$optional_symbols{$sym});
		    }
		}
	    }
	    if(!$optional_symbols{$sym}) {
	        $errs++;
	    }
	}
    }
    my $stext = get_words_sym($kern_fh, '_stext', 1);
    if($stext != BASE) {
	warn sprintf "In BASE (0x%08x) != _stext (0x%08x)\n",
			BASE, $stext, $kern_fn;
	$errs++;
    }
    die "$errs error", ($errs == 1 ? '' : 's'), " in finding kernel symbols\n"
	if($errs);
}

=back

=cut

1;



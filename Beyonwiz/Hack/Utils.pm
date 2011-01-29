package Beyonwiz::Hack::Utils;

=head1 NAME

Beyonwiz::Hack::Utils - Some functions to help implement patch modules for
Beyonwiz::Hack modules to use in bw_patcher.

=head1 SYNOPSIS

    use Beyonwiz::Hack::Utils qw(
        findMatchingPath findNewFile
        patchFile addFile copyFile
	insens
    );

=head1 FUNCTIONS

=over

=item C<< insens($insens) >>

Use the case-insensitive encoding of file/directory path names if
C<$insens> is non-zero, otherwise paths are used as-is.

=item C<< findMatchingPath($fw_dir, $path) >>

Given a directory for the root of an unpacked firmware directory
tree C<$fw_dir> and a path within it C<$path>, return a list of files
that match the path in the firmware, taking into account the encoding
of path names that's done in case-insensitive mode.
This is done using a file glob, so file name expansion will be done
on any file name expansion characters in either part of the name.
The case-insensitive encoding is only done on C<$path>.

If the returned list contains more than one path,
it's up to the caller to determine what to do.

=item C<< makeMatchingDirectoryPath($fw_dir, $path) >>

Given a directory for the root of an unpacked firmware directory
tree C<$fw_dir> and a path within it C<$path>,
create a list of directories representing the complete path,
taking into account any case-insensitive name mapping.

If the returned list contains more than one path,
it's up to the caller to determine what to do.

=item C<< findNewFile($fw_dir, $path, $exec) >>

Given a directory for the root of an unpacked firmware directory
tree C<$fw_dir>, a path within it C<$path> and a flag to set
whether the file should be executable return either a list of matching paths
found using C<< findMatchingPath($fw_dir, $path) >>, or if none match
the path name of a new file (the file is not created), again
taking into account the path-name encoding in case-insensitive mode
and doing a file glob.

=item C<< patchFile($file, $pattern, $patch, $after) >>

Given a C<$file>, a path to an existing file in the firmware
(probably generated using C<< findMatchingPath($fw_dir, $path) >>,
add the text in the string C<$patch> after (C<$after == 1>)
or before (C<$after == 0>) the line matching the Perl regular expression
in C<$match>.

C<$patch> must have the newlines and any indenting in the correct position
to "fit" properly in the file; in particular it probably should end
in a newline.

Returns the number of times the patch was added to the file.

Takes some care not to put DOS CRLF line endings in the file.

=item C<< substFile($file, $linePattern, $subsPattern, $repl, $global) >>

Given a C<$file>, a path to an existing file in the firmware
(probably generated using C<< findMatchingPath($fw_dir, $path) >>,
substitute the replacement C<$repl> for the Perl regular expreddion
C<$subsPattern> in all lines the line matching the regular expression
in C<$linePattern>.
Applies the substitution at all possible positions in the matched line
if C<$global> is true, otherwise at most once.

Takes some care not to put DOS CRLF line endings in the file.

=item C<< addFile($file, $patch, $exec) >>

Add a new file C<$file>, a path to an existing file in the firmware
(probably generated using C<< findMatchingPath($fw_dir, $path) >>,
containing the tezt in C<$patch>. The file will be marked as executable
in the firmware if C<$exec> is non-zero.

C<$patch> must have the newlines and any indenting in the correct position
to "fit" properly in the file; in particular it probably should end
in a newline.

Takes some care not to put DOS CRLF line endings in the file.

=item C<< pathTildeExpand() >>

Expands C<~> and C<~>I<username> home directory abbreviations in
C<$ENV{PATH}>. This is needed because Perl C<system> and C<exec>
functions don't do tilde expansions.

=back

=cut

use strict;
use warnings;

use File::Spec::Functions qw(canonpath catdir catfile catpath
				splitdir splitpath);
use File::Glob qw(:glob);
use Fcntl qw(	O_WRONLY O_CREAT O_TRUNC
		S_IFMT
		S_IRWXU S_IXUSR S_IRUSR S_IWUSR
		S_IRGRP S_IXGRP
		S_IROTH S_IXOTH);

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
        findMatchingPath makeMatchingDirectoryPath findNewFile
        patchFile substFile addFile copyFile
	insens
	pathTildeExpand
    );

my $insens;

sub insens($) {
    $insens = $_[0];
}

sub findMatchingPath($$) {
    my ($fw_dir, $path) = @_;
    if($insens) {
	my @segs = splitdir($path);
	foreach my $seg (@segs) {
	    $seg = '[0-9][0-9][0-9][rx]_' . $seg
		if(defined $seg && $seg ne '');
	}
	$path = catfile(@segs);
    }
    my ($vol, $dir) = splitpath($fw_dir, 1);
    my $search_path = catpath($vol, catfile($dir, $path), '');
    return bsd_glob($search_path, GLOB_NOCASE);
}

sub makeMatchingDirectoryPath($$) {
    my ($fw_dir, $path) = @_;
    my ($vol, $dir) = splitpath($fw_dir, 1);
    if($insens) {
	my @segs = splitdir($path);
	my @matchsegs;
	foreach my $seg (@segs) {
	    push @matchsegs,
		(defined $seg && $seg ne '' && $seg ne '.' && $seg ne '..'
		    ? '[0-9][0-9][0-9][rx]_' . $seg
		    : $seg);
	}

	my @matchpaths;
	while(@matchsegs) {
	    my $search_path = catpath($vol,
				    catdir($dir, catfile(@matchsegs)),
				    '');
	    @matchpaths = bsd_glob($search_path, GLOB_NOCASE);
	    last if(@matchpaths >= 1);
	    pop @matchsegs;
	}

	if(@segs - @matchsegs == 0) {
	    return @matchpaths;
	} else {
	    for(my $j = scalar(@matchsegs); $j < @segs; $j++) {
		$segs[$j] = '001x_' . $segs[$j];
	    }
	    $matchpaths[0] = $fw_dir if(!@matchpaths);
	    foreach my $pathmatch (@matchpaths) {
		($vol, $dir) = splitpath($pathmatch, 1);
		$pathmatch = catpath($vol,
				     catdir(splitdir($dir),
					    @segs[@matchsegs..$#segs]),
				     '');
	    }
	    return @matchpaths;
	}
    } else {
	return (catpath($vol, catdir(splitdir($dir), splitdir($path))), '');
    }
}

sub findNewFile($$$) {
    my ($fw_dir, $path, $exec) = @_;
    my @matches = findMatchingPath($fw_dir, $path);
    return @matches if(@matches);
    my @segs = splitdir($path);
    if(@segs > 1) {
	@matches = findMatchingPath($fw_dir, catdir(@segs[0..($#segs-1)]));
	return (@matches) if(!@matches);
    } else {
	@matches = ($fw_dir);
    }
    if($insens) {
	$segs[-1] = '001' . ($exec ? 'x' : 'r') . '_' . $segs[-1];
    }
    foreach my $match (@matches) {
	my ($vol, $dir) = splitpath($match, 1);
	$dir = catfile($dir, $segs[-1]);
	$match = catpath($vol, $dir, '');
    }
    return @matches;
}

sub patchFile($$$$) {
    my ($file, $pattern, $patch, $after) = @_;
    -f $file or die "Can't find file to patch: $file\n";
    my $oldf = $file . '.bak';
    rename $file, $oldf
	or die "Can't rename $file to $oldf\n";
    my $perms = (stat $oldf)[2] & ~S_IFMT;
    open OLDF, '<', $oldf
	or die "Can't open $oldf - $!\n";
    binmode OLDF;
    sysopen NEWF, $file, O_WRONLY|O_CREAT, $perms
	or die "Can't create new copy of $file - $!\n";;
    binmode NEWF;
    $patch =~ s/\015\012/\012/g;
    my $patches = 0;
    while(my $line = <OLDF>) {
	my $match = ($line =~ /$pattern/);
	if($match) {
	    if($after) {
		print NEWF $line, $patch;
	    } else {
		print NEWF $patch, $line;
	    }
	    $patches++;
	} else {
	    print NEWF $line;
	}
    }
    close OLDF;
    close NEWF;
    chmod $perms, $file;
    unlink $oldf;
    return $patches;
}

sub substFile($$$$$) {
    my ($file, $linePattern, $subsPattern, $repl, $global) = @_;
    -f $file or die "Can't find file to patch: $file\n";
    my $oldf = $file . '.bak';
    rename $file, $oldf
	or die "Can't rename $file to $oldf\n";
    my $perms = (stat $oldf)[2] & ~S_IFMT;
    open OLDF, '<', $oldf
	or die "Can't open $oldf - $!\n";
    binmode OLDF;
    sysopen NEWF, $file, O_WRONLY|O_CREAT, $perms
	or die "Can't create new copy of $file - $!\n";;
    binmode NEWF;
    $repl =~ s/\015\012/\012/g;
    my $patches = 0;
    while(my $line = <OLDF>) {
	if($line =~ /$linePattern/) {
	    if($global ? ($line =~ s/$subsPattern/$repl/eg)
		       : ($line =~ s/$subsPattern/$repl/e)) {
		warn "Patched line to: $line";
		$patches++;
	    }
	}
	print NEWF $line;
    }
    close OLDF;
    close NEWF;
    chmod $perms, $file;
    unlink $oldf;
    return $patches;
}

sub addFile($$$) {
    my ($file, $patch, $exec) = @_;
    my $perms;
    if(-f $file) {
	$perms = (stat $file)[2] & ~S_IFMT;
    } else {
	$perms = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH # 0644 for old-timers
    }
    $perms |= S_IXUSR | S_IXGRP | S_IXOTH # Add executable bit for all
	if($exec);
    sysopen NEWF, $file, O_WRONLY|O_CREAT, $perms
	or die "Can't create new copy of $file - $!\n";;
    binmode NEWF;
    $patch =~ s/\015\012/\012/g;
    print NEWF $patch;
    close NEWF;
    chmod $perms, $file;
}

sub copyFile($$$) {
    my ($file, $patch_file, $exec) = @_;
    open OLDF, '<', $patch_file
	or die "Can't open patch file $patch_file: $!\n";
    binmode OLDF;
    my $perms;
    if(-f $file) {
	$perms = (stat $file)[2] & ~S_IFMT;
    } else {
	$perms = (stat $patch_file)[2] & ~S_IFMT;
	$perms |= S_IRUSR | S_IRGRP | S_IROTH # 0444 for old-timers
    }
    $perms |= S_IXUSR | S_IXGRP | S_IXOTH # Add executable bit for all
	if($exec);
    sysopen NEWF, $file, O_WRONLY|O_CREAT|O_TRUNC, $perms
	or die "Can't create new copy of $file - $!\n";;
    binmode NEWF;
    my ($buf, $nread);
    while(($nread = sysread OLDF, $buf, 4096) > 0) {
	defined(syswrite NEWF, $buf, $nread)
	    or die "Error writing $file: $!\n";
    }
    die "Error reading $patch_file: $!\n"
	unless($nread == 0);
    close NEWF;
    close OLDF;
    chmod $perms, $file;
}

sub pathTildeExpand() {
    if(defined $ENV{PATH}) {
	my @path = split ':', $ENV{PATH};
	foreach my $p (@path) {
	    # Do tilde expansion. Shamelessly lifted from the Perl FAQs
	    $p =~ s{
	      ^~([^/]*)
	    }{
	      $1 ? (getpwnam($1))[7]
		 : ( $ENV{HOME} || $ENV{LOGDIR} )
	    }ex;
	}
	$ENV{PATH} = join ':', @path;
    }
}

1;

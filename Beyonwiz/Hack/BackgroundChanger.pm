package Beyonwiz::Hack::BackgroundChanger;

=head1 NAME

    Beyonwiz::Hack::BackgroundChanger;

=head1 SYNOPSIS

A module to use as an argument to use with L< C<bw_patcher>|bw_patcher/ >.
It modifies the firmware to display a different background image
in the full-screen menus.

The image file must be a JPEG image, 1280x720 pixels for Beyonwiz firmware
01.05.247 and earlier.

For firmware versions after 01.05.247, the image file must be a PNG
image, 1280x720 pixels.
The Beyonwiz then simply adds the constant GUI colour to that image,
so greyscale images will probably come out best. The maximum intensity
of each pixel in the image needs to be limited, otherwise the colour
values can wrap around after adding the GUI colouring and you get
weird effects.
The image in the original firmware has no pixel with RGB values
greater than (103, 103, 103) decimal (0x67, 0x67, 0x67). The Beyonwiz
base image is greyscale, but it has a colour map, so it's possible
that coloured colour mapped images may also work.

=head1 DISABLING THE HACK

Download unmodified firmware into the Beyonwiz and
restart.

=head1 FUNCTIONS

=over

=item C<< hack($flash_dir, $root_dir, $image_file) >>

Inserts C<$image_file> into the firmware instead of the
default C<wizdvp/guidata/bitmaps/wiz/total_image/Main-image-1.jpg>

=item C<< hackTag() >>

Returns C<bg> as the default suffix tag for the patch.

=back

=head1 PREREQUSITES

Uses packages
C<Image::Size>,
L<C<Beyonwiz::Hack::PutFile>|Beyonwiz::Hack::PutFile>
L<C<Beyonwiz::Hack::RemFile>|Beyonwiz::Hack::RemFile>
.

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

=cut

use strict;
use warnings;

use Image::Size;

use Beyonwiz::Hack::PutFile;
use Beyonwiz::Hack::RemFile;

sub hackTag() {
    return 'bg';
}

# Location of background image file in the flash filesystem
my $bg_image1 = 'wizdvp/guidata/bitmaps/wiz/total_image/Main-image-1.jpg';
my $bg_image2 = 'wizdvp/guidata/bitmaps/wiz/total_image/Main-image-2.png';

# Make it executable?
my $bg_image_exec = 1;

sub hack($$$) {
    my ($flash_dir, $root_dir, $image_file) = @_;

    my ($w, $h, $type) = imgsize($image_file);
    die "Error in $image_file: $type\n" unless defined $w and defined $h;

    die "$image_file must be a JPEG or a PNG image, is $type\n"
	unless($type eq 'JPG' or $type eq 'PNG');
    die "Image $image_file file is ${w}x${h}: must be 1280x720 pixels\n"
	unless($w == 1280 && $h == 720);

    my $update_image = $bg_image2;
    my $remove_image = $bg_image1;
    if($type eq 'JPG') {
	$update_image = $bg_image1;
	$remove_image = $bg_image2;
    }

    print "New background $update_image with $image_file\n";
    
    Beyonwiz::Hack::PutFile::hack($flash_dir, $root_dir,
    				'flash', $image_file,
				$update_image, $bg_image_exec);

    print "Removing background $remove_image\n";

    Beyonwiz::Hack::RemFile::hack($flash_dir, $root_dir,
    				'flash', $remove_image);
}

1;

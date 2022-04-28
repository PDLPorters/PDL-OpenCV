use strict;
use warnings;
use Test::More;

use PDL::LiteF;
use PDL::OpenCV::VideoCapture;

my $vfile='t/Megamind.avi';
my $vc = PDL::OpenCV::VideoCapture->new_uri($vfile);
isa_ok $vc, 'PDL::OpenCV::VideoCapture';
my $frame = $vc->read;
is_deeply [$frame->dims], [3,720,528], 'right dims' or diag $frame->info;

done_testing();

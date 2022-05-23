use strict;
use warnings;
use Test::More;

use PDL::LiteF;
use PDL::OpenCV;
use PDL::OpenCV::Videoio;

my $vfile='t/Megamind.avi';
my $vc = PDL::OpenCV::VideoCapture->new;
isa_ok $vc, 'PDL::OpenCV::VideoCapture';
die if !$vc->open($vfile);
my ($frame, $res) = $vc->read;
ok $res, 'read successful';
is_deeply [$frame->dims], [3,720,528], 'right dims' or diag $frame->info;
is $vc->get(CAP_PROP_FORMAT), CV_8UC1, 'video format';
is $vc->get(CAP_PROP_FRAME_WIDTH), 720, 'video format';

done_testing();

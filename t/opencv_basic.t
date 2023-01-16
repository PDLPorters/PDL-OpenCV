use strict;
use warnings;
use Test::More;

use PDL::LiteF;
use PDL::NiceSlice;
use PDL::OpenCV;
use PDL::OpenCV::Imgproc;

my $data = (xvals(5,8,3)+10*yvals(5,8,3)+zvals(1,1,3))->mv(2,0);
my $slice = float $data(0);
my $slice2 = long $data(0:2);

is_deeply [map $_->sclr, ($slice->minMaxLoc)[0..1]], [0,74],'minMaxIdx';
is PDL::OpenCV::CV_8UC3(), 16, 'depth constant';
is COLOR_GRAY2RGB, 8, 'colour-conversion constant exported';
is PDL::OpenCV::Imgproc::COLOR_GRAY2RGB, 8, 'constant in module space';
is PDL::OpenCV::Error::StsNullPtr, -27, 'deep namespace constant';

done_testing();

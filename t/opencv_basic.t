use strict;
use warnings;
use Test::More;

use PDL::LiteF;
use PDL::NiceSlice;
use PDL::OpenCV;

my $data = (xvals(5,8,3)+10*yvals(5,8,3)+zvals(1,1,3))->mv(2,0);
my $slice = float $data(0);
my $slice2 = long $data(0:2);

is_deeply [map $_->sclr, $slice->minMaxIdx], [0,74],'minMaxIdx';
is PDL::OpenCV::CV_8UC3(), 16, 'depth constant';
is PDL::OpenCV::COLOR_GRAY2RGB(), 8, 'colour-conversion constant';
is COLOR_GRAY2RGB, 8, 'colour-conversion constant exported';
is CAP_PROP_FORMAT, 8, 'capability constant exported';

done_testing();

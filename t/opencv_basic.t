use strict;
use warnings;
use Test::More;

use PDL::LiteF;
use PDL::NiceSlice;
use PDL::OpenCV;

sub tapprox {
  my($a,$b, $eps) = @_;
  $eps ||= 1e-6;
  my $diff = abs($a-$b);
  ref $diff eq 'PDL' and $diff = $diff->max;
  return $diff < $eps;
}

my $data = (xvals(5,8,3)+10*yvals(5,8,3)+zvals(1,1,3))->mv(2,0);
my $slice = float $data(0);
my $slice2 = long $data(0:2);

is( PDL::OpenCV::rows($slice), $data->dim(2),'rows' );
is( PDL::OpenCV::rows($slice2), $data->dim(2),'rows planes' );
is( PDL::OpenCV::cols($slice), $data->dim(1),'cols' );
is( PDL::OpenCV::cols($slice2), $data->dim(1),'cols planes' );
is_deeply [map $_->sclr, PDL::OpenCV::minMaxIdx($slice)], [0,74],'minMaxIdx';
is PDL::OpenCV::CV_8UC3(), 16, 'depth constant';
is PDL::OpenCV::COLOR_GRAY2RGB(), 8, 'colour-conversion constant';
is COLOR_GRAY2RGB, 8, 'colour-conversion constant exported';

done_testing();

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

my $data=xvals(5,8,3)+10*yvals(5,8,3)+zvals(1,1,3);
my $slice = float $data(,,0;-);
my $slice2 = long $data(,,0:2;-)->mv(2,0);

is( PDL::OpenCV::rows($slice), $data->dim(1),'rows' );
is( PDL::OpenCV::rows($slice2), $data->dim(1),'rows planes' );
is( PDL::OpenCV::cols($slice) , $data->dim(0),'cols' );
is( PDL::OpenCV::cols($slice2) , $data->dim(0),'cols planes' );
is PDL::OpenCV::cv_minmax($data->slice('0')).'', '[0 72 0 0]','cv_minmax';

done_testing();

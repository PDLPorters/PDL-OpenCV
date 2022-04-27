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
my $mw=PDL::OpenCV->new_mat($slice);
my ($cvtype,$pdltype)=$mw->mat_type;

my $mw2=PDL::OpenCV->new_mat($slice2);

is( PDL::OpenCV::rows($slice), $data->dim(1),'rows' );
is( PDL::OpenCV::rows($slice2), $data->dim(1),'rows planes' );
is( PDL::OpenCV::cols($slice) , $data->dim(0),'cols' );
is( PDL::OpenCV::cols($slice2) , $data->dim(0),'cols planes' );
my $g=zeroes($data(,,0));
$mw->get_data($g);
ok tapprox($data(,,0;-), $g(;-)),'getData';
ok tapprox($data(,,0;-), $mw->get_data->(;-)),'getData2';
$g=zeroes($data)->mv(2,0);
$mw2->get_data($g);
ok tapprox($data(,,;-)->mv(2,0), $g(;-)),'getData ch 3';
ok tapprox($data->mv(2,0), $mw2->get_data->(;-)),'getData2 ch 3';

my $b=yvals($slice);
my $ma=PDL::OpenCV->new_mat($b);
my $haha=$ma->get_data();
ok tapprox($b(;-), $haha(;-)),'getData - new_mat';
done_testing();

#!/usr/bin/perl 

use strict;
use warnings;
use Test::More;

use PDL::LiteF;
use PDL::NiceSlice;
use PDL::OpenCV;
use 5.10.0;

sub tapprox {
  my($a,$b, $eps) = @_;
  $eps ||= 1e-6;
  my $diff = abs($a-$b);
    # use max to make it perl scalar
  ref $diff eq 'PDL' and $diff = $diff->max;
  return $diff < $eps;
}

my $data=rvals(5,6,2);
my $mw=PDL::OpenCV->new_mat($data(,,0;-)->copy);

say "new_mat completed. Starting tests";
say "at ",$mw->mat_at(4,4),$data(4,4,0);

for my $x (0..4)  {
	for my $y (0..5) {
#		is( tapprox( $data($x,$y,0;-), $mw->mat_at($x,$y)),  1,"mat_at $x, $y" );
	}
}
say "rows: ",$mw->rows;
#say "cols2 ",$mw->cols2;
is( $mw->rows(), $data->dim(0),'rows' );
is( $mw->cols() , $data->dim(1),'cols' );
exit;
my $g=$mw->get_data($data(,,0;-));
say "val 4 4 ",$g(4,4);
say "$g ",$data(,,0);
is( tapprox ($data(,,0;-)-$g),1,'getData');
$mw->mat_destroy;
done_testing();


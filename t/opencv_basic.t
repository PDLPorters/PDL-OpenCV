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

my $data=xvals(5,8,2)+10*yvals(5,8,2);
my $slice = float $data(,,0;-);
my $slice2 = float $data(,,0;-)->transpose;
#my $dr=$slice->get_dataref;
#say $data(0,0,0;-);
#say ("5,6,5,$dr");
#my $mw=PDL::OpenCV->nMat(5,6,5,$slice) ; #->get_dataref);
my $mw=PDL::OpenCV->new_mat($slice);
my ($cvtype,$pdltype)=$mw->type;
#say "cvtype $cvtype pdltype $pdltype";

#say "new_mat completed. Starting tests";
#say "at ",$mw->mat_at(4,4),$data(4,4,0);
is(approx($mw->mat_at(4,4),$data(4,4,0)),1,'MatAt');

for my $x (0..2)  {
	for my $y (0..2) {
		is( $slice->($x,$y), $mw->mat_at($x,$y),"mat_at $x, $y" );
		#say ( $slice->($x,$y;-), ", ",$mw->mat_at($x,$y),"mat_at $x, $y" );
	}
}
#say "rows: ",$mw->rows;
#say "cols2 ",$mw->cols2;
is( $mw->rows(), $data->dim(1),'rows' );
is( $mw->cols() , $data->dim(0),'cols' );
my $g=zeroes($data(,,0;-));
$mw->get_data($g);
#say "val 4 4 ",$g(4,4);
#say "$g ",$data(,,0);
is( tapprox ($data(,,0;-)->transpose-$g->transpose),1,'getData');

my $dummy=ones($slice);
my $ma; #=PDL::OpenCV->new_mat($dummy);
$ma=$mw->convertTo(2);
#convertTo($mw,$ma,2);
#say "Ma $ma";

my $h;
$h=$ma->get_data();
#say $h;
is( tapprox ($data(,,0;-)->transpose-$h),1,'getData');
done_testing();


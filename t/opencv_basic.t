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

my $data=xvals(5,8,3)+10*yvals(5,8,3)+zvals(1,1,3);
my $slice = float $data(,,0;-);
my $slice2 = long $data(,,0:2;-)->mv(2,0);
#my $dr=$slice->get_dataref;
#say $data(0,0,0;-);
#say ("5,6,5,$dr");
#my $mw=PDL::OpenCV->nMat(5,6,5,$slice) ; #->get_dataref);
my $mw=PDL::OpenCV->new_mat($slice);
my $mw2=PDL::OpenCV->new_mat($slice2);
my ($cvtype,$pdltype)=$mw->type;
#say "cvtype $cvtype pdltype $pdltype";

#say "new_mat completed. Starting tests";
#say "at ",$mw->mat_at(4,4),$data(4,4,0);
is(approx($mw->mat_at(4,4),$data(4,4,0)),1,'MatAt');
is(tapprox($mw2->mat_at(4,2),$data(4,2,;-)),1,'MatAt-planes');

for my $x (0..2)  {
	for my $y (0..2) {
		is( $slice->($x,$y), $mw->mat_at($x,$y),"mat_at $x, $y" );
		is( tapprox($data($x,$y,;-)-$mw2->mat_at($x,$y)),1,"mat_at2 $x, $y" );
		#say ( $data($x,$y,;-), ", ",$mw2->mat_at($x,$y),"mat_at $x, $y" );
	}
}
#say "rows: ",$mw->rows;
#say "cols2 ",$mw->cols2;
is( $mw->rows(), $data->dim(1),'rows' );
is( $mw2->rows(), $data->dim(1),'rows planes' );
is( $mw->cols() , $data->dim(0),'cols' );
is( $mw2->cols() , $data->dim(0),'cols planes' );
my $g=zeroes($data(,,0));
$mw->get_data($g);
#say "val 4 4 ",$g(4,4);
#say "$g ",$data(,,0);
is( tapprox ($data(,,0;-)-$g(;-)),1,'getData');
is( tapprox ($data(,,0;-)-$mw->get_data->(;-)),1,'getData2');
$g=zeroes($data)->mv(2,0);
$mw2->get_data($g);
is( tapprox ($data(,,;-)->mv(2,0)-$g(;-)),1,'getData ch 3');
is( tapprox ($data->mv(2,0)-$mw2->get_data->(;-)),1,'getData2 ch 3');

#my $dummy=ones($slice);
my $ma; #=PDL::OpenCV->new_mat($dummy);
$ma=$mw->convertTo(2);
#convertTo($mw,$ma,2);
#say "Ma $ma";


my $h;
$h=$ma->get_data();
#say $h;
is( $ma->type , short->numval,'data type conversion');
is( tapprox ($data(,,0;-)->transpose-$h),1,'getData - converted');
my $b=yvals($slice);
$ma->set_data($b);
$h=$ma->get_data();
say ($b->squeeze,$h);
#is( tapprox ($b->transpose-$h),1,'getData - set_data');
$ma=PDL::OpenCV->new_mat($b);
$h=$ma->get_data();
say ($b->squeeze,$h);
is( tapprox ($b(;-)-$h(;-)),1,'getData - new_mat');
done_testing();


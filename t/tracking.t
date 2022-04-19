#!/usr/bin/perl 

use strict;
use warnings;
use Test::More;

use PDL::LiteF;
use PDL::NiceSlice;
use PDL::OpenCV;
use PDL::IO::FlexRaw;
use PDL::OpenCV::Tracking;
use 5.10.0;

sub tapprox {
  my($a,$b, $eps) = @_;
  $eps ||= 1e-6;
  my $diff = abs($a-$b);
    # use max to make it perl scalar
  ref $diff eq 'PDL' and $diff = $diff->max;
  return $diff < $eps;
}


#my $data=rvals(128,128,74);
#my $data; #=float readflex('/data/ingo/daten/c-31p/7T_data/C31P_MRS_45-1/conv/c_0074')->squeeze;
my $vfile='t/Megamind.avi';
my $data=vread($vfile);
#my $slice = float $data(,,0;-);
#my $dr=$slice->get_dataref;
say $data->info;
#say $data(50,50,0;-);
#say ("5,6,5,$dr");
#my $mw=PDL::OpenCV->nMat(5,6,5,$slice) ; #->get_dataref);
my $bx=pdl(qw/60 45 30 50/);
my ($tr,$box,$mw)=PDL::OpenCV::Tracking->init_tracker($data(,,0,;-),2,$bx) ; #);
#my ($tr,$box,$mw)=PDL::OpenCV::Tracking->init_tracker($data(,,0,;-),2) ;# ,pdl(qw/20 20 30 10/));

say "new_mat completed. Starting tests";
say "box $box";
#say "at ",$mw->mat_at(80,50),$data(80,50,0);
say "at (get_data",$mw->get_data()->(,4,4);

for my $x (1..$data->dim(2)-1)  {
	print "Next x $x ";
	#say $mw->cv_minmax,$data(,,$x)->minmax;
	($box,$mw) = $tr->update_tracker($data(,,$x;-));
	is(all ($box) >0,1,"tracker found box $x.");
	say "x $x box $box";
}

done_testing();


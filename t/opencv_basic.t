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

my $data=rvals(128,128,10);
my $mw=PDL::OpenCV->new_mat($data(,,0;-));

say "new_mat completed. Starting tests";

is( tapprox( $data(48,48,0;-), $mw->mat_at(48,48)),  1,'mat_at' );

done_testing();


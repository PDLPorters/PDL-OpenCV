#!/usr/bin/perl

use 5.10.0;
use PDL::NiceSlice;
use strict;

use PDL;
use PDL::Tracking qw/init_tracker update_tracker/;

my $data=rvals(128,128,10);
my $box=zeroes(4);
my $tracker=2;
say "data 48 48 ",$data(48,48,0);
#set_image($data(,,0));
# gplot (with=>'image',$data);
my $mat;

my ($to, $box, $mo) = PDL::Tracking::init_tracker($data(,,0),$tracker,$box); #,$box,$tracker,);
    say "init tracker $to, matrix $mo";
	say "box $box";

for my $j (1..9) {
        $box=update_tracker($data(,,$j),$to,$mo); #,$box,$tracker,);
        say "$j $box";
}



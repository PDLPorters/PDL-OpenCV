use strict;
use warnings;
use Test::More;

use PDL::LiteF;
use PDL::NiceSlice;
use PDL::OpenCV;
use PDL::OpenCV::Tracking;

sub tapprox {
  my($a,$b, $eps) = @_;
  $eps ||= 1e-6;
  my $diff = abs($a-$b);
  ref $diff eq 'PDL' and $diff = $diff->max;
  return $diff < $eps;
}

my $vfile='t/Megamind.avi';
my $data=vread($vfile);
create_video($data,'t/test_write.avi',20,'MP4V');

note $data->info;
my $bx=pdl(qw/169 88 192 257/);
my ($tr,$box,$mw)=PDL::OpenCV::Tracking->init_tracker($data(,,,1,;-),2,$bx) ; #);

note "box $box";
note "at (get_data",$mw->get_data()->(,4,4);

for my $x (2..$data->dim(3)-1)  {
	($box,$mw) = $tr->update_tracker($data(,,,$x;-));
	if ($x<98 || $x > 153 && $x<200) {
		is(all ($box) >0,1,"tracker found box $x.");
	} else {
		is(all ($box) == 0,1,"tracker did not fiund box $x.");
	}
	note "x $x box $box";
}

done_testing();

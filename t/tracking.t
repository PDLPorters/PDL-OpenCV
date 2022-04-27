use strict;
use warnings;
use Test::More;

use PDL::LiteF;
use PDL::NiceSlice;
use PDL::OpenCV;
use PDL::OpenCV::Tracker;
use File::Temp qw(tempfile);

sub tapprox {
  my($a,$b, $eps) = @_;
  $eps ||= 1e-6;
  my $diff = abs($a-$b);
  ref $diff eq 'PDL' and $diff = $diff->max;
  return $diff < $eps;
}

my $vfile='t/Megamind.avi';
is video_dims($vfile).'', '[16 3 720 528 270]', 'video_dims';
my $data=vread($vfile);
(undef, my $outfile) = tempfile(SUFFIX=>'.avi');
create_video($data,$outfile,20,'MP4V');

note $data->info;
my $bx=pdl(qw/169 88 192 257/);
my ($tr,$box)=PDL::OpenCV::Tracker->init_tracker($data(,,,1,;-),2,$bx);

note "box $box";

for my $x (2..$data->dim(3)-1)  {
	$box = $tr->update_tracker($data(,,,$x;-));
	if ($x<98 || $x > 153 && $x<200) {
		is(all ($box) >0,1,"tracker found box $x.");
	} else {
		is(all ($box) == 0,1,"tracker did not find box $x.");
	}
	note "x $x box $box";
}

done_testing();

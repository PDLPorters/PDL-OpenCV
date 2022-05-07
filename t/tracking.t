use strict;
use warnings;
use Test::More;

use PDL::LiteF;
use PDL::NiceSlice;
use PDL::OpenCV;
use PDL::OpenCV::Tracker;
use PDL::OpenCV::VideoCapture;
use PDL::OpenCV::VideoWriter;
use File::Temp qw(tempfile);

my $vfile='t/Megamind.avi';
my $vc = PDL::OpenCV::VideoCapture->new;
isa_ok $vc, 'PDL::OpenCV::VideoCapture';
die if !$vc->open($vfile);
my $frame = $vc->read;
is_deeply [$frame->dims], [3,720,528], 'right dims' or diag $frame->info;
my $x = 1;
$frame = $vc->read for 1..$x; # blank frames

(undef, my $outfile) = tempfile(SUFFIX=>'.avi');
my $writer = PDL::OpenCV::VideoWriter->new;
eval {
  $writer->open($outfile, 'MP4V', 20, (map $frame->dim($_), 1,2), 1);
};
is $@, '';

note $frame->info;
my $bx=pdl(qw/169 88 192 257/);
my ($tr,$box)=PDL::OpenCV::Tracker->init_tracker($frame,$bx);
note "box $box";

while (defined $frame) {
	$box = $tr->update_tracker($frame);
	if ($x<98 || $x > 153 && $x<200) {
		is(all ($box) >0,1,"tracker found box $x.");
	} else {
		is(all ($box) == 0,1,"tracker did not find box $x.");
	}
	note "x $x box $box";
	$writer->write($frame);
	$frame = $vc->read;
	$x++;
}

done_testing();

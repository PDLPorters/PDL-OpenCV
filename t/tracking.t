use strict;
use warnings;
use Test::More;
use PDL::LiteF;
use PDL::OpenCV;
use PDL::OpenCV::Highgui;
use PDL::OpenCV::Imgproc;
use PDL::OpenCV::Tracker;
use PDL::OpenCV::VideoCapture;
use PDL::OpenCV::VideoWriter;
use File::Temp qw(tempfile);

my $vfile='t/Megamind.avi';
my $vc = PDL::OpenCV::VideoCapture->new;
die if !$vc->open($vfile);
my ($frame, $res) = $vc->read;
ok $res, 'read a frame right';
is_deeply [$frame->dims], [3,720,528], 'right dims' or diag $frame->info;
my $x = 1;
($frame, $res) = $vc->read for 1..$x; # blank frames

(undef, my $outfile) = tempfile(SUFFIX=>'.avi');
is my $fcc = fourcc(split '', 'MP4V'), 1446269005, 'fourcc right value';
my $writer = PDL::OpenCV::VideoWriter->new;
ok $writer->open($outfile, $fcc, 20, [map $frame->dim($_), 1,2], 1), 'open worked';

my $box=pdl(qw/169 88 192 257/);
my $tr = PDL::OpenCV::Tracker->new;
if ($box->at(0) == 0) {
  namedWindow("ud",WINDOW_NORMAL);
  $box = selectROI("ud",$frame,1,0);
  destroyWindow("ud");
}
$box = $tr->init(frame_scale($frame),$box);

while ($res) {
  ($box, my $track_res) = $tr->update($frame = frame_scale($frame));
  rectangle($frame, $box, [255,0,0,0], 2, 1, 0);
  imshow("ud", $frame);
  waitKey(1);
  if ($x<98 || $x > 153 && $x<200) {
          is(all ($box) >0,1,"tracker found box $x.");
          ok $track_res, 'tracker said found';
  } else {
          is(all ($box) == 0,1,"tracker did not find box $x.");
          ok !$track_res, 'tracker said not found';
  }
  note "x $x box $box";
  $writer->write($frame);
  ($frame, $res) = $vc->read;
  $x++;
}

done_testing();

sub frame_scale {
  my ($frame) = @_;
  my ($min, $max) = PDL::OpenCV::minMaxIdx($frame);
  $frame = ($frame * (255/$max))->byte if $max->sclr != 255;
  $frame->dim(0) == 1 ? $frame->cvtColor(COLOR_GRAY2RGB) : $frame;
}

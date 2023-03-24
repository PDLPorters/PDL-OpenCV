use strict;
use warnings;
use Test::More;
use PDL::LiteF;
use PDL::OpenCV;
use PDL::OpenCV::Highgui;
use PDL::OpenCV::Imgproc;
use PDL::OpenCV::Tracking;
use PDL::OpenCV::Videoio;
use PDL::OpenCV::Objdetect;

{
  my $imgb = zeroes 3,500,500;
  for (1..2) {
    my $cpy = $imgb->copy;
    my ($pts) = ellipse2Poly([250,250],[200,100],45,60,120+$_,1);
    rectangle($cpy, $_, $_+1, [255,0,0,0]) for $pts->dog;
    imshow("ud", $cpy);
    waitKey(50);
  }
}

my $cc = PDL::OpenCV::CascadeClassifier->new;
my $CC_DIR = '';
my ($loaded) = $cc->load($CC_DIR.'/haarcascades/haarcascade_frontalface_alt.xml') if $CC_DIR;
die "Failed to load" if $CC_DIR and !$loaded;

my $vfile='t/Megamind.avi';
my $vc = PDL::OpenCV::VideoCapture->new;
die if !$vc->open($vfile, CAP_ANY);
isnt $vc->getBackendName, undef, 'getBackendName works';
my ($frame, $res) = $vc->read;
ok $res, 'read a frame right';
is_deeply [$frame->dims], [3,720,528], 'right dims' or diag $frame->info;
my $x = 1;
($frame, $res) = $vc->read for 1..$x; # blank frames

is my $fcc = PDL::OpenCV::VideoWriter::fourcc(split '', 'MP4V'), 1446269005, 'fourcc right value';

my $box=pdl(qw/169 88 192 257/);
my $tr = PDL::OpenCV::TrackerKCF->new;
if ($box->at(0) == 0) {
  namedWindow("ud",WINDOW_NORMAL);
  $box = selectROI("ud",$frame,1,0);
  destroyWindow("ud");
}
$box = $tr->init(frame_scale($frame),$box);

my $lsd = PDL::OpenCV::LineSegmentDetector->new(LSD_REFINE_STD);

while ($res) {
  ($box, my $track_res) = $tr->update($frame = frame_scale($frame));
  my ($lines) = $lsd->detect(my $gray = cvtColor($frame, COLOR_BGR2GRAY));
  my ($binary) = threshold($gray, 127, 255, 0);
  my ($contours) = findContours($binary,RETR_TREE,CHAIN_APPROX_SIMPLE,[0,0]);
  my ($bx, $by, $bw, $bh) = @{ $box->unpdl };
  rectangle($frame, [$bx,$by], [$bx+$bw,$by+$bh], [255,0,0,0], 2, 1, 0);
  drawContours($frame,$contours,-1,[0,255,0,0]);
  $lsd->drawSegments($frame, $lines);
  if ($CC_DIR) {
    my ($objects) = $cc->detectMultiScale(equalizeHist($gray));
    for ($objects->dog) {
      my ($bx, $by, $bw, $bh) = @{ $_->unpdl };
      rectangle($frame, [$bx,$by], [$bx+$bw,$by+$bh], [0,255,255,0], 2, 1, 0);
    }
  }
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
  ($frame, $res) = $vc->read;
  $x++;
}

done_testing();

sub frame_scale {
  my ($frame) = @_;
  my ($min, $max) = PDL::OpenCV::minMaxLoc($frame->clump(2)->dummy(0));
  $frame = ($frame * (255/$max))->byte if $max->sclr != 255;
  $frame->dim(0) == 1 ? cvtColor($frame, COLOR_GRAY2RGB) : $frame;
}

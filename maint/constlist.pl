use strict;
use warnings;
use File::Spec::Functions;

# perl maint/constlist.pl /usr/include/opencv4/

die "No dir given" unless -d ($ARGV[0]||'') and my $dir = $ARGV[0];

process_header(catfile(qw(Imgproc constlist.txt)), catfile($dir, qw(opencv2 imgproc.hpp)), 'ColorConversionCodes');
process_header(catfile(qw(Videoio constlist.txt)), catfile($dir, qw(opencv2 videoio.hpp)), 'VideoCaptureProperties');
process_header(catfile(qw(Highgui constlist.txt)), catfile($dir, qw(opencv2 highgui.hpp)), 'WindowFlags');

sub process_header {
  my ($of, $f, $enum) = @_;
  open my $ofh, '>', $of or die "$of: $!";
  my $text = do { open my $fh, '<', $f or die "$f: $!"; local $/; <$fh> };
  my ($vals) = $text =~ /enum\s*$enum\s*\{(.*?)\}/s or die "enum not found";
  $vals =~ s#//.*?$##gm;
  print $ofh "$_\n" for $vals =~ /(\S+)\s*=/g;
}

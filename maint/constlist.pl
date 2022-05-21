use strict;
use warnings;
use File::Spec::Functions;

# perl maint/constlist.pl /usr/include/opencv4/ >constlist.txt

die "No dir given" unless -d ($ARGV[0]||'') and my $dir = $ARGV[0];

process_header(catfile($dir, qw(opencv2 imgproc.hpp)), 'ColorConversionCodes');
process_header(catfile($dir, qw(opencv2 videoio.hpp)), 'VideoCaptureProperties');
process_header(catfile($dir, qw(opencv2 highgui.hpp)), 'WindowFlags');

sub process_header {
  my ($f, $enum) = @_;
  my $text = do { open my $fh, '<', $f or die "$f: $!"; local $/; <$fh> };
  my ($vals) = $text =~ /enum\s*$enum\s*\{(.*?)\}/s or die "enum not found";
  $vals =~ s#//.*?$##gm;
  print "$_\n" for $vals =~ /(\S+)\s*=/g;
}

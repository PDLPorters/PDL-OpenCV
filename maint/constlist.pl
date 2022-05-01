use strict;
use warnings;
use File::Spec::Functions;

die "No dir given" unless -d ($ARGV[0]||'') and my $dir = $ARGV[0];

my $f = catfile $dir, qw(opencv2 imgproc.hpp);
my $text = do { open my $fh, '<', $f or die "$f: $!"; local $/; <$fh> };
my ($enum) = $text =~ /enum\s*ColorConversionCodes\s*\{(.*?)\}/s or die "enum not found";
$enum =~ s#//.*?$##gm;
my @enums = $enum =~ /(\S+)\s*=/g;
print "$_\n" for @enums;

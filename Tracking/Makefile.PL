use strict;
use warnings;
use PDL::Core::Dev;            # Pick up development utilities
use ExtUtils::MakeMaker;
use File::Spec::Functions;

my $package = ["tracking.pd",'Tracking','PDL::OpenCV::Tracking'];
my %hash = pdlpp_stdargs($package);
$hash{VERSION_FROM} = '../opencv.pd';
$hash{INC} .= ' -I..';
our $libs;
$hash{LIBS}[0] .= $libs;

our @cw_objs;
$hash{LDFROM} .= join ' ', '', '$(OBJECT)', map catfile(updir, $_), @cw_objs;
$hash{NO_MYMETA} = 1;

use ExtUtils::CppGuess;
my %cpp_opts = ExtUtils::CppGuess->new->makemaker_options;
$hash{dynamic_lib} = $cpp_opts{dynamic_lib};

undef &MY::postamble;
*MY::postamble = sub { pdlpp_postamble($package); };

WriteMakefile(%hash);

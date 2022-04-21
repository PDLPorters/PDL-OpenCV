use PDL::Core::Dev;            # Pick up development utilities
use ExtUtils::MakeMaker;
use Config;

$package = ["tracking.pd",Tracking,PDL::OpenCV::Tracking];
%hash = pdlpp_stdargs($package);
#$hash{OBJECT} .= ' additional_Ccode$(OBJ_EXT) ';
$hash{clean}->{FILES} .= ' todelete_Ccode$(OBJ_EXT) ';
$hash{'VERSION_FROM'} = '../opencv.pd';
$hash{INC} .= ' -I../cw';
my @pkgs = qw(opencv4);
$hash{LIBS}[0] .= (
  eval {require PkgConfig; join ' ', map PkgConfig->find($_)->get_ldflags, @pkgs} ||
  eval {require ExtUtils::PkgConfig; join ' ', map ExtUtils::PkgConfig->libs($_), @pkgs} ||
  `pkg-config @pkgs --libs`);

use Config;
$hash{LDFROM} .= ' $(OBJECT) ../cw/build/libopencv_wrapper'.$Config{lib_ext};
$hash{NO_MYMETA} = 1;

use ExtUtils::CppGuess;
my %cpp_opts = ExtUtils::CppGuess->new->makemaker_options;
$hash{dynamic_lib} = $cpp_opts{dynamic_lib};

WriteMakefile(%hash);

sub MY::postamble { pdlpp_postamble($package); }

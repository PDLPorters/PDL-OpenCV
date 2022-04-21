use strict;
use warnings;
use PDL::Core::Dev;            # Pick up development utilities
use File::Spec::Functions;
use ExtUtils::MakeMaker;

my $package = ["opencv.pd",'OpenCV','PDL::OpenCV'];
my %hash = pdlpp_stdargs($package);
#$hash{OBJECT} .= ' additional_Ccode$(OBJ_EXT) ';
$hash{clean}->{FILES} .= ' todelete_Ccode$(OBJ_EXT) ';
$hash{'VERSION_FROM'} = 'opencv.pd';
my @pkgs = qw(opencv4);
our $libs = (
  eval {require PkgConfig; join ' ', map PkgConfig->find($_)->get_ldflags, @pkgs} ||
  eval {require ExtUtils::PkgConfig; join ' ', map ExtUtils::PkgConfig->libs($_), @pkgs} ||
  `pkg-config @pkgs --libs`);
$hash{LIBS}[0] .= $libs;

$hash{INC} .= ' -Icw';

use Config;
$hash{NO_MYMETA} = 1;

use ExtUtils::CppGuess;
my %cpp_opts = ExtUtils::CppGuess->new->makemaker_options;
$hash{dynamic_lib} = $cpp_opts{dynamic_lib};

%hash = (%hash,
    NAME                => 'PDL::OpenCV',
    AUTHOR              => 'Ingo Schmid',
    LICENSE => 'perl',
    CONFIGURE_REQUIRES => {
        'ExtUtils::CppGuess' => '0.21',
        'ExtUtils::MakeMaker' => '6.3002',
        'Alien::cmake3' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'PDL'        => '2.4.4',
    },
    DIR                 => ['cw','Tracking'],
    MYEXTLIB => catfile(qw(cw build libopencv_wrapper$(LIB_EXT))),
);
WriteMakefile(%hash);

sub MY::postamble {
  my ($self) = @_;
  pdlpp_postamble($package) .
    sprintf "\n".'$(MYEXTLIB) : %s'."\n\t".$self->cd('cw', '$(MAKE) $(PASSTHRU)')."\n",
      catfile(qw(cw $(FIRST_MAKEFILE)));
}

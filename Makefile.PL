use strict;
use warnings;
use PDL::Core::Dev;            # Pick up development utilities
use File::Spec::Functions;
use ExtUtils::MakeMaker;

my $package = ["opencv.pd",'OpenCV','PDL::OpenCV'];
my %hash = pdlpp_stdargs($package);
$hash{clean}{FILES} .= ' t/test_write.avi ';
$hash{'VERSION_FROM'} = 'opencv.pd';
my @pkgs = qw(opencv4);
our $libs = (
  eval {require PkgConfig; join ' ', map PkgConfig->find($_)->get_ldflags, @pkgs} ||
  eval {require ExtUtils::PkgConfig; join ' ', map ExtUtils::PkgConfig->libs($_), @pkgs} ||
  `pkg-config @pkgs --libs`);
$hash{LIBS}[0] .= $libs;
our $inc = (
  eval {require PkgConfig; join ' ', map PkgConfig->find($_)->get_cflags, @pkgs} ||
  eval {require ExtUtils::PkgConfig; join ' ', map ExtUtils::PkgConfig->cflags($_), @pkgs} ||
  `pkg-config @pkgs --cflags`);

$hash{INC} .= ' -Icw';

use Config;
$hash{NO_MYMETA} = 1;

use ExtUtils::CppGuess;
my %cpp_opts = ExtUtils::CppGuess->new->makemaker_options;
$hash{dynamic_lib} = $cpp_opts{dynamic_lib};

our @cw_objs = map catfile(qw(cw), $_.'$(OBJ_EXT)'), qw(generated_cvwrapper opencv_wrapper);

%hash = (%hash,
    NAME                => 'PDL::OpenCV',
    AUTHOR              => 'Ingo Schmid',
    LICENSE => 'perl',
    CONFIGURE_REQUIRES => {
        'ExtUtils::CppGuess' => '0.21',
        'ExtUtils::MakeMaker' => '6.3002',
        'PDL'        => '2.078', # broadcastloop
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'PDL'        => '2.078', # broadcastloop
    },
    DIR                 => ['cw','Tracking'],
    MYEXTLIB => join(' ', @cw_objs),
);
WriteMakefile(%hash);

sub MY::postamble {
  my ($self) = @_;
  pdlpp_postamble($package) .
    join(' : ', @cw_objs) . "\n" . # sequence so no parallel-cd+build
    sprintf "\n".'$(MYEXTLIB) : %s'."\n\t".$self->cd('cw', '$(MAKE) $(PASSTHRU)')."\n",
      catfile(qw(cw $(FIRST_MAKEFILE)));
}

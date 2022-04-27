use strict;
use warnings;
use PDL::Core::Dev;            # Pick up development utilities
use ExtUtils::MakeMaker;

my @pkgs = qw(opencv4);
our $libs = (
  eval {require PkgConfig; join ' ', map PkgConfig->find($_)->get_ldflags, @pkgs} ||
  eval {require ExtUtils::PkgConfig; join ' ', map ExtUtils::PkgConfig->libs($_), @pkgs} ||
  `pkg-config @pkgs --libs`);
our $inc = (
  eval {require PkgConfig; join ' ', map PkgConfig->find($_)->get_cflags, @pkgs} ||
  eval {require ExtUtils::PkgConfig; join ' ', map ExtUtils::PkgConfig->cflags($_), @pkgs} ||
  `pkg-config @pkgs --cflags`);

my $package = ["opencv.pd",'OpenCV','PDL::OpenCV'];
my %hash = pdlpp_stdargs($package);
$hash{clean}{FILES} .= ' opencv_wrapper.h opencv_wrapper.cpp';
$hash{LIBS}[0] .= $libs;
$hash{INC} .= " $inc";

use ExtUtils::CppGuess;
my %cpp_opts = ExtUtils::CppGuess->new->makemaker_options;
$hash{dynamic_lib} = $cpp_opts{dynamic_lib};

our @cw_objs = map $_.'$(OBJ_EXT)', qw(generated_cvwrapper opencv_wrapper);

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
    MYEXTLIB => join(' ', @cw_objs),
    depend => {"@cw_objs"=>'opencv_wrapper.h generated_cvwrapper.h'},
);
WriteMakefile(%hash);

sub MY::postamble {
  my ($self) = @_;
  my $cccmd = $self->const_cccmd;
  $cccmd =~ s/CCCMD/CXXCMD/;
  $cccmd =~ s/\$\(CC\)/$cpp_opts{CC}/;
  $cccmd =~ s/(\$\(OPTIMIZE\)).*/$cpp_opts{CCFLAGS} $1/s;
  pdlpp_postamble($package) .
    sprintf <<'EOF', $cccmd;
%1$s

generated_cvwrapper.cpp : generated_cvwrapper.h # impose sequence so only run once
generated_cvwrapper.h : genwrap.pl
	$(PERLRUN) genwrap.pl

generated_cvwrapper$(OBJ_EXT) : generated_cvwrapper.cpp
	$(CXXCMD) $(CCCDLFLAGS) generated_cvwrapper.cpp

opencv_wrapper$(OBJ_EXT) : opencv_wrapper.cpp
	$(CXXCMD) $(CCCDLFLAGS) opencv_wrapper.cpp
EOF
}

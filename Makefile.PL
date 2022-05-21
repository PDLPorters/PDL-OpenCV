use strict;
use warnings;
use PDL::Core::Dev;            # Pick up development utilities
use ExtUtils::MakeMaker;
use File::Spec::Functions qw(catfile curdir);

require ''. catfile curdir, 'submodmf.pl';
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
our ($cppg_cc, $cppg_cflags) = @cpp_opts{qw(CC CCFLAGS)};

our @cw_objs = map $_.'$(OBJ_EXT)', qw(opencv_wrapper);

%hash = (%hash,
    NAME                => 'PDL::OpenCV',
    AUTHOR              => 'Ingo Schmid',
    LICENSE => 'perl',
    CONFIGURE_REQUIRES => {
        'ExtUtils::CppGuess' => '0.21',
        'ExtUtils::MakeMaker' => '6.3002',
        'PDL'        => '2.079', # typemap-search in dirs above
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'PDL'        => '2.079',
    },
    MYEXTLIB => join(' ', @cw_objs),
    depend => {
      'opencv_wrapper$(OBJ_EXT)'=>'opencv_wrapper.h',
      'opencv_wrapper.h OpenCV.pm'=>'constlist.txt funclist.pl genpp.pl', # .pm because that deps on .pd
    },
);
WriteMakefile(%hash);

sub cxx_cmd {
  my ($self, $cppg_cc, $cppg_cflags) = @_;
  my $cccmd = $self->const_cccmd;
  $cccmd =~ s/CCCMD/CXXCMD/;
  $cccmd =~ s/\$\(CC\)/$cppg_cc/;
  $cccmd =~ s/(\$\(OPTIMIZE\)).*/$cppg_cflags $1\n/s;
  $cccmd;
}
sub cpp_comp {
  join "\n", map "$_\$(OBJ_EXT) : $_.cpp\n\t\$(CXXCMD) \$(CCCDLFLAGS) $_.cpp\n", @_;
}
sub MY::postamble {
  my ($self) = @_;
  my $cxx_cmd = cxx_cmd($self, $cppg_cc, $cppg_cflags);
  my $cxx_compile = cpp_comp(@cw_objs);
  pdlpp_postamble($package) .
    "\n" . <<'EOF' . "\n" . $cxx_cmd . $cxx_compile;
opencv_wrapper.cpp : opencv_wrapper.h # impose sequence so only run once
opencv_wrapper.h : genwrap.pl
	$(PERLRUN) genwrap.pl
EOF
}

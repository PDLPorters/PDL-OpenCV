use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::CppGuess;

our $inc;
WriteMakefile(
    NAME                => 'PDL::OpenCV::CWrapper',
    SKIP   => [qw(all static dynamic install)],
    clean => {FILES => 'generated_cvwrapper.h generated_cvwrapper.cpp'},
    OBJECT => 'generated_cvwrapper$(OBJ_EXT) opencv_wrapper$(OBJ_EXT)',
    depend => {'$(OBJECT)'=>'opencv_wrapper.h generated_cvwrapper.h'},
    INC => $inc,
    ExtUtils::CppGuess->new->makemaker_options,
    NO_MYMETA=>1,
);

sub MY::top_targets {
  my ($self) = @_;
  <<'EOF';
all :: static

pure_all :: static

static :: $(OBJECT)

generated_cvwrapper.cpp : generated_cvwrapper.h # impose sequence so only run once
generated_cvwrapper.h : genwrap.pl
	$(PERLRUN) genwrap.pl

EOF
}

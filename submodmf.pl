use strict;
use warnings;
use PDL::Core::Dev;            # Pick up development utilities
use ExtUtils::MakeMaker;
use File::Spec::Functions;
our (%cpp_opts, @cw_objs);

sub wmf {
  my ($last, $hdrs, $classes) = @_;
  my $pkg = "PDL::OpenCV::$last";
  my $package = [lc($last).".pd",$last,$pkg];
  my %hash = pdlpp_stdargs($package);
  $hash{VERSION_FROM} = catfile(updir, 'opencv.pd');
  $hash{INC} .= ' -I'.updir;
  our $libs;
  $hash{LIBS}[0] .= $libs;
  $hash{clean}{FILES} .= join ' ', '', map "$_.h $_.cpp", qw(wraplocal);
  $hash{OBJECT} .= join ' ', '', map $_.'$(OBJ_EXT)', qw(wraplocal);
  $hash{depend} = {
    '$(OBJECT)'=>catfile(updir, 'opencv_wrapper.h') . ' wraplocal.h',
    "$last.pm wraplocal.h"=>join(' ', catfile(updir, 'genpp.pl'), 'funclist.pl', (!-f 'constlist.txt' ? () : ('constlist.txt'))),
    "$last.c"=>catfile(updir, 'typemap'),
    (!-f 'constlist.txt' ? () : ("wraplocal.h"=>'constlist.txt')),
  };
  $hash{LDFROM} .= join ' ', '', '$(OBJECT)', map catfile(updir, $_), @cw_objs;
  $hash{NO_MYMETA} = 1;
  $hash{dynamic_lib} = $cpp_opts{dynamic_lib};
  undef &MY::postamble;
  *MY::postamble = sub {
    my ($self) = @_;
    join "\n", pdlpp_postamble($package),
      genwrap_from('wraplocal', 1, join(',', '', @$hdrs), @$classes),
      cpp_build($self, 'wraplocal');
  };
  WriteMakefile(%hash);
}

1;

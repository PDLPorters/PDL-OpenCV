  use PDL::Core::Dev;            # Pick up development utilities
  use ExtUtils::MakeMaker;

  $package = ["tracking.pd",OCV,PDL::OCV];
  %hash = pdlpp_stdargs($package);
  #$hash{OBJECT} .= ' additional_Ccode$(OBJ_EXT) ';
  $hash{clean}->{FILES} .= ' todelete_Ccode$(OBJ_EXT) ';
  $hash{'VERSION_FROM'} = 'tracking.pd';
  push @{$hash{  'LIBS' }},    '-ltracker_wrapper';

  WriteMakefile(%hash);

  sub MY::postamble { pdlpp_postamble($package); }

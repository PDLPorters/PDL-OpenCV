  use PDL::Core::Dev;            # Pick up development utilities
  use ExtUtils::MakeMaker;

  $package = ["opencv.pd",OpenCV,PDL::OpenCV];
  %hash = pdlpp_stdargs($package);
  #$hash{OBJECT} .= ' additional_Ccode$(OBJ_EXT) ';
  $hash{clean}->{FILES} .= ' todelete_Ccode$(OBJ_EXT) ';
  $hash{'VERSION_FROM'} = 'opencv.pd';
  push @{$hash{  'LIBS' }},    '-ltracker_wrapper';

  WriteMakefile(%hash);

  sub MY::postamble { pdlpp_postamble($package); }

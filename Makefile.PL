use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PDL::OpenCV',
    AUTHOR              => 'Ingo Schmid',
    VERSION_FROM        => 'OpenCV/opencv.pd',
    LICENSE => 'perl',
    CONFIGURE_REQUIRES => {
        'ExtUtils::CppGuess' => '0.21',
        'ExtUtils::MakeMaker' => '6.3002',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'PDL'        => '2.4.4',
    },
    DIR                 => ['OpenCV', 'Tracking',],
    clean               => { FILES => ['PDL-OpenCV-*'] },
);

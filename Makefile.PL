use strict;
use warnings;
use ExtUtils::MakeMaker;

use Getopt::Long;

my $force;
my $result = GetOptions("force"=>\$force);


WriteMakefile(
    NAME                => 'PDL::OpenCV',
    AUTHOR              => 'Ingo Schmid',
    VERSION_FROM        => 'OpenCV/opencv.pd',
    ABSTRACT_FROM       => 'OpenCV/opencv.pd',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PREREQ_PM => {
        'Test::More' => 0,
        'PDL'        => '2.4.4',
    },
    CCFLAGS => `pkg-config --cflags opencv4`,
#    LDDLFLAGS => `pkg-config --libs opencv4`,
    PREREQ_FATAL        => 0,
    DIR                 => ['OpenCV', 'Tracking',],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => ['PDL-OpenCV-*'] },
);

sub MY::postamble {
    my $text =
'
install ::
	@echo "Updating PDL documentation database ..."
	@$(PERL) add_doc.pl

';

    return $text;
}

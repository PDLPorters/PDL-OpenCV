#!perl
use 5.10.0;
use strict;

# define generated functions.
# [ name , \%options , \@arguments
my @funclist = (
['convertTo',{method=>1,},' MatWrapper *','out','int','type',],
['normalize',{},' MatWrapper *','out','int','start','int','end','int','type'],
);

sub gen_code { 
	my $name =shift;
	my $opt =shift;
	my @args; 
	my @cvargs ;
	for my $j (0..$#_/2) {
		#push @types,$s;
		my $s=$_[2*$j];
		my $v=$_[2*$j+1];
		push @args, "$s $v";
		($s=~ /.*Wrapper \*/) ? push (@cvargs, "$v\->mat") : push @cvargs, "$v";
	}
	my $ret=$$opt{ret} || "int";
	my $fname=$name;
	my $str = "$ret cw_$name ( MatWrapper * mw ";
	my $argstr = join (", " ,@args) ; #$types[$i] $vals[$i]"), map { "$_ ".$args{$_} } keys (%args));
	my $cvargs = join (', ',@cvargs);
	$str .= ', '. $argstr if $argstr;
	$str.= ") ";
	$name=$$opt{fucntion} if $$opt{function};
	my $hstr = $str.";\n";
	$str.="{\n$ret retval;\n";
	if (ref ($$opt{map_args}) eq 'CODE') {
		my $fun  = $$opt{map_args};
		&fun($argstr);
	}
	$str.= $$opt{pre}."\n";
	my $lh ; #= 'void ';
	$lh = "$$opt{cvret} cvret = " if $$opt{cvret};
	$str.=$lh."mw->mat.$name ( $cvargs );\n" if $$opt{method};
	$str.=$lh."$name ( mw->mat,$cvargs );\n" unless $$opt{method};
	$str.= $$opt{post} || ("retval = cvret\n") if ($$opt{cvret} ) ;
	$str.= "\n return retval; \n}\n";
	return ($hstr,$str);
}

say join ", ",@_;
my $mkcmd = shift;

open my $fh,">generated_cvwrapper.h" ||die "cannot write header file\n";
open my $fc,">generated_cvwrapper.cpp" ||die "cannot write header file\n";

print $fc '
#include "generated_cvwrapper.h"
#include "opencv_wrapper.h"
#include <opencv2/opencv.hpp>
#include <opencv2/tracking.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>

using namespace std;
using namespace cv;
/* use C name mangling */
#ifdef __cplusplus
extern "C" {
#endif

';


print $fh '

#ifndef GENERATED_CVWRAPPER_H
#define GENERATED_CVWRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

#include "opencv_wrapper.h"

';

for my $func (@funclist) {
	my ($hstr,$cstr) = gen_code( @$func );
	print $fh $hstr;
	print $fc $cstr;
}

print $fh '
#ifdef __cplusplus
}
#endif


#endif // 
';

print $fc '
#ifdef __cplusplus
}
#endif

';

close $fh;
close $fc;
mkdir 'build' unless (-d 'build') ;
chdir 'build';
my $exit = `cmake .. && make $mkcmd `;
die "(c)make returned with exit code $exit\n" if ($exit);




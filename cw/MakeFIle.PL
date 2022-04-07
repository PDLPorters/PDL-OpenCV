#!perl
use 5.10.0;
use strict;
use PDL::Types;
use PDL::Core qw/howbig/;

# define generated functions.
# [ name , \%options , \@arguments
my @funclist = (
['convertTo',{method=>1,
	pre=>'
		try { out->mat.cols; } catch (...) { out = new MatWrapper; }; 
		type=get_ocvtype(type,CV_MAT_CN(mw->mat.type()));',
	post=>'
		out->vmat=vector(1,out->mat); 
		out->dp=out->mat.data;',
	},'MatWrapper *','out','int','type',],
['normalize',{},'MatWrapper *','out','int','start','int','end','int','type'],
['channels',{cvret=>'int',method=>1,postxx=>'printf("res channels %d\n",res);',},,],
['minMaxIdx',{method=>0,post=>'//printf("c: min %f max %f\n",mymin[0],mymax[0]);'},"double *","mymin","double *","mymax"],
#['mult',{method=>0,post=>'//printf("c: min %f max %f\n",mymin[0],mymax[0]);'},"double *","mymin","double *","mymax"],
#['minMaxLoc',{method=>0,},"double *","mymin","double *","mymax","int *","myminl","int *","mymaxl"],
);

my ($tstr_l,$mstr_l,$rstr_l,$gstr_l,$gstr_l2,$astr_l2);
for my $type ( PDL::Types::types ) {
	next unless $type->real;
	my $ts=$type->ppsym;
	next if $ts =~/[KPQEN]/;
	my $nt = $type->numval;
	my $ct = $type->realctype;	
	my $it = ( $type->integer ? '' : 'F');	
	my $st = ( $type->unsigned ? 'U' : 'S');
	my $tt = ( $type->integer ? $st.$it : $it);
	my $s = PDL::Core::howbig($type)*8;
	$tstr_l.="\tcase $nt :
		//printf(\"cv type %d\\n\",CV_$s$tt\C(planes));
		return CV_$s$tt\C(planes); break;\n";
	$mstr_l.="\tcase $nt : $ct * fdata = ($ct * ) data; break;\n";
	$rstr_l.="\tcase CV_$s$tt : t = $nt; break;\n";
	$gstr_l.="\t$ct * ${ts}data=reinterpret_cast <$ct *>(rdata);\n";
	$gstr_l2.="\t\t\tcase CV_$s$tt : ${ts}data[(j*cols+i)*ch+c] = frame.ptr<$ct>(j)[ch*i+c];\n
	//printf(\"MatAt data at i %d j %d ch %d %g\\n\",i, j, ch,${ts}data[c] );
	\t\t\t break;\n";
	$astr_l2.="\t\t\tcase CV_$s$tt : ${ts}data[c] = frame.ptr<$ct>(i)[ch*j+c];\n
	//printf(\"MatAt data at i %d j %d ch %d %g\\n\",i, j, ch,${ts}data[c] );
	\t\t\t break;\n";
	#$astr_l.="\t\t\tcase CV_$s$tt : ${ts}data = frame.data[frame.channels()*(frame.cols*y + x) + 0];
}

my $astr="
int MatAt (const MatWrapper * mw,const ptrdiff_t j,const ptrdiff_t i,void * rdata) {
	ptrdiff_t lins=mw->mat.rows;
	ptrdiff_t cols=mw->mat.cols;
	int type=mw->mat.type();
	int cvtype=mw->mat.type();
	int ch=mw->mat.channels();
	//printf(\"MatAt: data pointer %p\\n\",mw->mat.data);
	//printf(\"MatAt: piddle data pointer %p\\n\",rdata);
	//printf(\"MatAt: data tyep %d\\n\",type);
	uchar depth = CV_MAT_DEPTH(type); //	type & CV_MAT_DEPTH_MASK;
	uchar chans = 1 + (type >> CV_CN_SHIFT);
	cv::Mat frame=mw->mat;
	$gstr_l;
	for (int c = 0; c<ch; c++) {
		switch ( depth ) {
		$astr_l2;
		}
	}
	return get_pdltype(cvtype);
}
";

# getDataCopy
my $gstr="
int getDataCopy(const MatWrapper * mw,void * rdata, ptrdiff_t vl) {
	printf(\"getDataCopy: vl %d\\n\",vl);
	printf(\"getDataCopy: rdata %p\\n\",rdata);
	ptrdiff_t lins=mw->mat.rows;
	ptrdiff_t cols=mw->mat.cols;
	int cvtype=mw->mat.type();
	int ch=mw->mat.channels();
	Mat frame;
	uchar depth = CV_MAT_DEPTH(cvtype); //    type & CV_MAT_DEPTH_MASK;
	printf(\"getDataCopy: cvtype %d\\n\",depth);
	printf(\"getDataCopy: vl %d\\n\",vl);
	if (vl > 0) {
	try {vl=mw->vmat.size(); } catch (...) { vl=1;} // default to 0 if not a vector
	//printf(\"getDataCopy: vl %d\\n\",vl);
	} else vl = 1;
	$gstr_l 
	//printf(\"getDataCopy: mw->mat %p\\n\",mw->mat);
	//printf(\"getDataCopy: mw->vmat[0] %p\\n\",mw->vmat[0]);
	for (ptrdiff_t v = 0; v<vl; v ++ ) { //  iterate over vmax;
		frame=mw->vmat[v];
		printf(\"frame %d cols %d rows %d channels %d\\n\",v,frame.cols,frame.rows,frame.channels());
		for ( ptrdiff_t i = 0; i<cols; i++ ) {
			for ( ptrdiff_t j = 0; j<lins; j++ ) {
				for (int c = 0; c<ch; c++) {
					switch (depth) {
					$gstr_l2
					}
				}
			}
		}
	}
	return get_pdltype(cvtype);
}
";

# get_pdltype
my $rstr="
int get_pdltype(const int cvtype) {
        uchar depth = CV_MAT_DEPTH(cvtype); //    type & CV_MAT_DEPTH_MASK;
        const uchar chans = CV_MAT_CN(cvtype) ; //1 + (cvtype >> CV_CN_SHIFT);
	int t=-1;
	//printf(\"ConvertTo cvtype %d\\n\",cvtype);
	switch(depth) {
		$rstr_l
\t}\n
	return t;
}\n
";


# get_ocvtype
my $tstr="
int get_ocvtype(const int datatype,const int planes ) { 
	switch (datatype) { \n
		$tstr_l;
\t}\n
	return -1;
}\n
";

my $mstr="

MatWrapper * newMat (const ptrdiff_t cols, const ptrdiff_t rows, const int type, const int planes, void * data) {
	int cvtype = map_types(type,planes);
	MatWrapper * mw = new MatWrapper;
	switch(type)
	$mstr_l;
        mw->mat = frame;
	mw->vmat = vector<Mat>(1,frame);
        mw->dp=frame.data;
        //printf (\"mw->at 0 0 (newMat) %f\\n\",mw->mat.at<float>(0,0));
        return  mw;
}\n
";

open my $fm, ">maptypes.h";
print $fm "
#ifndef MAP_DATATYPES_H
#define MAP_DATATYPES_H

#include <vector>
struct MatWrapper
{
        cv::Mat mat;
        void * dp;
	std::vector<cv::Mat> vmat;

};

";
print $fm $tstr;
print $fm $rstr;
print $fm "
#endif\n";
close $fm;


sub gen_code { 
	my $name =shift;
	my $opt =shift;
	my @args; 
	my @cvargs ;
	# parse argument list and get mats
	for my $j (0..$#_/2) {
		#push @types,$s;
		my $s=$_[2*$j];
		my $v=$_[2*$j+1];
		#push @args, "$s $v";
		($v=~ /^\&/) ? push (@args, "$s ".$v=~s/\&//r) : push @args, "$s $v";
		($s=~ /.*Wrapper \*/) ? push (@cvargs, "$v\->mat") : push @cvargs, "$v";
	}
	my $ret=$$opt{ret} || "int";
	my $fname=$name;
	my $str = "$ret cw_$name ( MatWrapper * mw ";
	my $argstr = join (", " ,@args) ; #$types[$i] $vals[$i]"), map { "$_ ".$args{$_} } keys (%args));
	my $cvargs = join (', ',@cvargs);
	$cvargs='' if ($cvargs =~ /^\s*,\s*$/);
	$str .= ', '. $argstr unless ($argstr =~ /^\s*$/);
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
	# {cvret} is the return type. 
	$lh = "$$opt{cvret} cvret = " if $$opt{cvret};
	$str.=$lh."mw->mat.$name ( $cvargs );\n" if $$opt{method};
	$cvargs=", $cvargs" if $cvargs;
	$str.=$lh."$name ( mw->mat $cvargs );\n" unless $$opt{method};
	say "generate code: post:\n$$opt{post}\n";
	$str.= "// post: \n".$$opt{post};
	$str.= ("retval = cvret;\n") if (!$$opt{post} && $$opt{cvret} ) ;
	$str.= "\n return retval; \n}\n\n\n";
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

#include "maptypes.h"
';

print $fc $gstr;
print $fc $astr;

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




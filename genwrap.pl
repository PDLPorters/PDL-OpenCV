use strict;
use warnings;
use File::Spec::Functions;
use PDL::Types;
use PDL::Core qw/howbig/;

my @funclist = do './funclist.pl'; die if $@;

my ($tstr_l,$rstr_l);
for my $type ( grep $_->real, PDL::Types::types ) {
	next if (my $bs = PDL::Core::howbig($type)) > 8;
	next if $type->ppsym =~/[KPQN]/;
	my $nt = $type->numval;
	my $ct = $type->realctype;
	my $tt = $type->integer ? ($type->unsigned ? 'U' : 'S') : 'F';
	my $s = 8*$bs;
	$tstr_l.="\tcase $nt: return CV_$s${tt}C(planes); break;\n";
	$rstr_l.="\tcase CV_$s$tt: return $nt; break;\n";
}

my $rstr="
int get_pdltype(const int cvtype) {
	switch(CV_MAT_DEPTH(cvtype)) {
$rstr_l\t}
	return -1;
}
";

my $tstr="
int get_ocvtype(const int datatype,const int planes) {
	switch (datatype) {
$tstr_l\t}
	return -1;
}
";

sub gen_code {
	my ($class, $name, $ismethod, $ret, $opt, @params) = @_;
	die "No class given for method='$ismethod'" if !$class and $ismethod;
	my (@args, @cvargs, $methodvar);
	if ($ismethod) {
		my ($s, $v) = @{shift @params};
		push @args, "$s $v";
		$methodvar = $v;
	}
	die "Error on $class/$name: attribute but args\n" if $ismethod == 2 and @params;
	while (@params) {
		my ($s, $v) = @{shift @params};
		push @args, "$s $v";
		push @cvargs, $s =~ /.*Wrapper\s*\*/ ? "$v->held" : $v;
	}
	my $fname = join '_', grep length, 'cw', $class, $name;
	my $str = "$ret $fname(";
	$str .= join(", ", @args) . ")";
	my $hstr = $str.";\n";
	$str .= " {\n";
	$str .= "  // pre:\n$$opt{pre}\n" if $$opt{pre};
	$str .= "  ".($ret ne 'void' ? "$ret retval = " : '');
	$str .= $ismethod == 0 ? join('::', grep length, "cv", $class, $name)."(" :
	  "$methodvar->held.$name" . ($ismethod == 1 ? "(" : ";\n");
	$str .= join(', ', @cvargs).");\n" if $ismethod != 2;
	$str .= "  // post:\n$$opt{post}\n" if $$opt{post};
	$str .= "  return retval;\n" if $ret ne 'void';
	$str .= "}\n\n";
	return ($hstr,$str);
}

open my $fh,">","opencv_wrapper.h" or die "cannot write header file\n";
open my $fc,">","opencv_wrapper.cpp" or die "cannot write C++ file\n";

print $fc sprintf qq{#line %d "%s"\n}, __LINE__ + 2,  __FILE__;
print $fc <<'EOF';
#include "opencv_wrapper.h"
#include <opencv2/opencv.hpp>
#include <opencv2/tracking.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/videoio.hpp>
#include <opencv2/core/utility.hpp>
#include <opencv2/videoio.hpp>

#if CV_VERSION_MINOR >= 5 && CV_VERSION_MAJOR >= 4
# define TRACKER_RECT_TYPE cv::Rect
#else
# define TRACKER_RECT_TYPE cv::Rect2d
#endif

using namespace std;
/* use C name mangling */
#ifdef __cplusplus
extern "C" {
#endif

EOF

print $fh sprintf qq{#line %d "%s"\n}, __LINE__ + 2,  __FILE__;
print $fh <<'EOF';
#ifndef OPENCV_WRAPPER_H
#define OPENCV_WRAPPER_H

#ifdef __cplusplus
#include <vector>
#include <opencv2/opencv.hpp>
#endif

#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>

typedef struct {
	int x; int y; int width; int height;
} cw_Rect;

EOF

sub gen_wrapper {
  my ($class, $ptr_only) = @_;
  (
    <<EOF, #hstr
typedef struct ${class}Wrapper ${class}Wrapper ;
${class}Wrapper *new${class}();
int delete${class}(${class}Wrapper * wrapper);
EOF
    <<EOF, #cstr
struct ${class}Wrapper {
	@{[$ptr_only ? "cv::Ptr<cv::${class}>" : "cv::${class}"]} held;
};
@{[$ptr_only ? '' : "${class}Wrapper *new${class}() {
	return new ${class}Wrapper;
}"]}
int delete${class}(${class}Wrapper * wrapper) {
	delete wrapper;
	return 1;
}
EOF
  );
}

for (['Mat'], ['Size'], ['VideoCapture'], ['VideoWriter'], ['Tracker',1]) {
  my ($hstr, $cstr) = gen_wrapper(@$_);
  print $fh $hstr;
  print $fc $cstr;
}

print $fc sprintf qq{#line %d "%s"\n}, __LINE__ + 2,  __FILE__;
print $fc <<'EOF';
TrackerWrapper *newTracker() {
	TrackerWrapper * Tr = new TrackerWrapper;
	Tr->held = cv::TrackerKCF::create();
	return Tr;
}

void initTracker(TrackerWrapper * Tr, MatWrapper * mw, cw_Rect box) {
	double mymin,mymax;
	cw_minMaxIdx(mw, & mymin,& mymax);
	double scale = 256/mymax;
	MatWrapper *framew = newMat();
	cw_Mat_convertTo(mw,framew,cw_const_CV_8UC3(),scale,0);
	if(cw_Mat_channels(framew)==1) cw_cvtColor(framew,framew,cw_const_COLOR_GRAY2RGB());
	cv::Rect roi = { box.x, box.y, box.width, box.height };
	if (roi.x == 0) {
		cv::namedWindow("ud",cv::WINDOW_NORMAL);
		roi=cv::selectROI("ud",framew->held,true,false);
		cv::destroyWindow("ud");
	}
	Tr->held->init(framew->held,roi);
	deleteMat(framew);
}

char updateTracker(TrackerWrapper * Tr, MatWrapper * mw, cw_Rect *roi) {
	double mymin,mymax;
	cw_minMaxIdx(mw, & mymin,& mymax);
	double scale = 256/mymax;
	MatWrapper *framew = newMat();
	cw_Mat_convertTo(mw,framew,cw_const_CV_8UC3(),scale,0);
	if(cw_Mat_channels(framew)==1) cw_cvtColor(framew,framew,cw_const_COLOR_GRAY2RGB());
	TRACKER_RECT_TYPE box;
	char res = Tr->held->update(framew->held,box);
	*roi = { (int)box.x, (int)box.y, (int)box.width, (int)box.height };
	cv::rectangle( framew->held, box, cv::Scalar( 255, 0, 0 ), 2, 1 );
	mw->held=framew->held;
	deleteMat(framew);
	cw_imshow("ud", mw);
	cv::waitKey(1);
	return res;
}

MatWrapper * newMatWithDims (const ptrdiff_t cols, const ptrdiff_t rows, const int type, int planes, void * data) {
	MatWrapper *mw = new MatWrapper;
	mw->held = cv::Mat(rows, cols, get_ocvtype(type,planes), data);
	return mw;
}

void cw_Mat_pdlDims(MatWrapper *wrapper, int *t, ptrdiff_t *l, ptrdiff_t *c, ptrdiff_t *r) {
	*t = get_pdltype(wrapper->held.type());
	*l = wrapper->held.channels();
	*c = wrapper->held.cols;
	*r = wrapper->held.rows;
}

SizeWrapper *newSizeWithDims(int width, int height) {
	SizeWrapper *mw = new SizeWrapper;
	mw->held = cv::Size(width, height);
	return mw;
}

ptrdiff_t framecountVideoCapture(VideoCaptureWrapper *wrapper) {
	return wrapper->held.get(cv::CAP_PROP_FRAME_COUNT);
}
EOF

print $fc $tstr;
print $fc $rstr;

print $fh sprintf qq{#line %d "%s"\n}, __LINE__ + 2,  __FILE__;
print $fh <<'EOF';
void cw_Mat_pdlDims(MatWrapper *wrapper, int *t, ptrdiff_t *l, ptrdiff_t *c, ptrdiff_t *r);

SizeWrapper *newSizeWithDims(int width, int height);

ptrdiff_t framecountVideoCapture(VideoCaptureWrapper *wrapper);

void initTracker(TrackerWrapper * Tr, MatWrapper * frame, cw_Rect box);
char updateTracker(TrackerWrapper *, MatWrapper *, cw_Rect *box);

MatWrapper * newMatWithDims (const ptrdiff_t cols, const ptrdiff_t rows, const int type, const int planes, void * data);

int get_pdltype(const int cvtype);
int get_ocvtype(const int datatype,const int planes);
EOF

for my $func (@funclist) {
	my ($hstr,$cstr) = gen_code( @$func );
	print $fh $hstr;
	print $fc $cstr;
}

sub add_const {
  my ($fh, $fc, $args, $text) = @_;
  (my $funcname = $text) =~ s#cv::##;
  my $t = "int cw_const_$funcname(@{[@$args ? join(',',map qq{@$_}, @$args) : '']})";
  print $fh "$t;\n";
  print $fc "$t { return $text@{[@$args ? '('.join(',',map $_->[1], @$args).')' : '']}; }\n";
}

for my $bits (qw(8UC 8SC 16UC 16SC 32SC 32FC 64FC)) {
  add_const($fh, $fc, [], "CV_$bits$_") for 1..4;
  add_const($fh, $fc, [[qw(int n)]], "CV_$bits");
}

open my $consts, '<', 'constlist.txt' or die "constlist.txt: $!";
while (!eof $consts) {
  chomp(my $line = <$consts>);
  add_const($fh, $fc, [], "cv::$line");
}

print $fh <<'EOF';

#ifdef __cplusplus
}
#endif

#endif
EOF

print $fc <<'EOF';
#ifdef __cplusplus
}
#endif
EOF

close $fh;
close $fc;

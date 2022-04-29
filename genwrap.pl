use strict;
use warnings;
use File::Spec::Functions;
use PDL::Types;
use PDL::Core qw/howbig/;

# define generated functions.
# [ name , \%options , \@arguments
my @funclist = (
['normalize',{},'MatWrapper *','out','int','start','int','end','int','type'],
['channels',{cvret=>'int',method=>1,postxx=>'printf("res channels %d\n",res);',},,],
['minMaxIdx',{method=>0,post=>'//printf("c: min %f max %f\n",mymin[0],mymax[0]);'},"double *","mymin","double *","mymax"],
#['mult',{method=>0,post=>'//printf("c: min %f max %f\n",mymin[0],mymax[0]);'},"double *","mymin","double *","mymax"],
#['minMaxLoc',{method=>0,},"double *","mymin","double *","mymax","int *","myminl","int *","mymaxl"],
);

my ($tstr_l,$rstr_l);
for my $type ( PDL::Types::types ) {
	next unless $type->real;
	my $ts=$type->ppsym;
	next if $ts =~/[KPQEN]/;
	my $nt = $type->numval;
	my $ct = $type->realctype;
	my $it = ( $type->integer ? '' : 'F');
	my $st = ( $type->unsigned ? 'U' : 'S');
	my $tt = ( $type->integer ? $st.$it : $it);
	my $bs = PDL::Core::howbig($type);
	my $s = 8*$bs;
	$tstr_l.="\tcase $nt :
		//printf(\"cv type %d\\n\",CV_$s${tt}C(planes));
		return CV_$s${tt}C(planes); break;\n";
	$rstr_l.="\tcase CV_$s$tt : t = $nt; break;\n";
}

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

my $tstr="
int get_ocvtype(const int datatype,const int planes) {
	switch (datatype) { \n
		$tstr_l;
\t}\n
	return -1;
}\n
";

sub gen_code {
	my $name =shift;
	my $opt =shift;
	my @args;
	my @cvargs ;
	# parse argument list and get mats
	for my $j (0..$#_/2) {
		#push @types,$s;
		my $s=$_[2*$j] || '';
		my $v=$_[2*$j+1] || '';
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
	$name=$$opt{function} if $$opt{function};
	my $hstr = $str.";\n";
	$str.="{\n$ret retval;\n";
	if (ref ($$opt{map_args}) eq 'CODE') {
		my $fun  = $$opt{map_args};
		&fun($argstr);
	}
	$str.= ($$opt{pre}||'')."\n";
	my $lh = '';
	# {cvret} is the return type.
	$lh = "$$opt{cvret} cvret = " if $$opt{cvret};
	$str.=$lh."mw->mat.$name ( $cvargs );\n" if $$opt{method};
	$cvargs=", $cvargs" if $cvargs;
	$str.=$lh."$name ( mw->mat $cvargs );\n" unless $$opt{method};
	$str.= "// post: \n".($$opt{post}||'');
	$str.= ("retval = cvret;\n") if (!$$opt{post} && $$opt{cvret} ) ;
	$str.= "\n return retval; \n}\n\n\n";
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

using namespace std;
/* use C name mangling */
#ifdef __cplusplus
extern "C" {
#endif

struct TrackerWrapper {
	cv::Ptr<cv::Tracker> tracker;
};

TrackerWrapper * newTracker(int trackerNumber) {
	string trackerTypes[8] = {"BOOSTING", "MIL", "KCF", "TLD","MEDIANFLOW", "GOTURN", "MOSSE", "CSRT"};
	string trackerType = trackerTypes[trackerNumber];
	//printf ("init tracker \n");
	cv::Ptr<cv::Tracker> tracker;
	// create a tracker object
	//if (trackerType == "BOOSTING")
		//tracker = cv::TrackerBoosting::create();
	if (trackerType == "MIL")
		tracker = cv::TrackerMIL::create();
	if (trackerType == "KCF")
		tracker = cv::TrackerKCF::create();
	/*if (trackerType == "TLD")
		tracker = cv::TrackerTLD::create();
	if (trackerType == "MEDIANFLOW")
		tracker = cv::TrackerMedianFlow::create();*/
	if (trackerType == "GOTURN")
		tracker = cv::TrackerGOTURN::create();
	//if (trackerType == "MOSSE")
		//tracker = cv::TrackerMOSSE::create();
	if (trackerType == "CSRT")
		tracker = cv::TrackerCSRT::create();
	// Ptr<Tracker> tracker = cv::TrackerKCF::create();
	TrackerWrapper * Tr= new TrackerWrapper;
	Tr->tracker = tracker;
	//printf ("init tracker done.\n");
	return Tr;
}

int deleteTracker(TrackerWrapper * wrapper) {
	delete wrapper;
	return 1;
}

int initTracker(TrackerWrapper * Tr, MatWrapper * mw, bBox * box ){
	cv::Rect roi;
	cv::Mat frame;
	roi.x=box->x;
	roi.y=box->y;
	roi.height=box->height;
	roi.width=box->width;
	double mymin,mymax;
	minMaxIdx(mw->mat, & mymin,& mymax);
	double scale = 256/mymax;
	mw->mat.convertTo(frame,CV_8UC3,scale);
	if(frame.channels()==1) cvtColor(frame,frame,cv::COLOR_GRAY2RGB);
	if (roi.x == 0) {
		cv::namedWindow("ud",cv::WINDOW_NORMAL);
		roi=cv::selectROI("ud",frame,true,false);
		cv::destroyWindow("ud");
	}
	Tr->tracker->init(frame,roi);
	printf("initTracker ROI x=%d y=%d width=%d height=%d frame c=%d r=%d\n",roi.x,roi.y,roi.width,roi.height,frame.cols,frame.rows); fflush(stdout);
	//printf ("at 48 48 (init_tracker %f\n",frame->mat.at<float>(48,48));
	box->x=roi.x;
	box->y=roi.y;
	box->width=roi.width;
	box->height=roi.height;
	return 1;
}

int updateTracker(TrackerWrapper * Tr, MatWrapper * mw, bBox * roi) {
#if CV_VERSION_MINOR >= 5 && CV_VERSION_MAJOR >= 4
	cv::Rect box;
#else
	cv::Rect2d box;
#endif
	cv::Mat frame;
	double mymin,mymax;
	minMaxIdx(mw->mat, & mymin,& mymax);
	double scale = 256/mymax;
	mw->mat.convertTo(frame,CV_8UC3,scale);
	printf ("updateTracker matrix c=%d r=%d\n", frame.cols, frame.rows); fflush(stdout);
	if(frame.channels()==1) cvtColor(frame,frame,cv::COLOR_GRAY2RGB);
	//printf ("ud: min/max %f %f \n",mymin,mymax);
	/*
	if ( mw->mat.type() > 4 ) {
		cv::normalize(mw->mat,frame, 1,0, NORM_MINMAX) ; //, -1,CV_8UC1);
	} else {
		frame=256*256/mymax*mw->mat; //.clone();
	}
	*/
	//printf ("Empty matrix %d\n",frame.empty());
	minMaxIdx(mw->mat, & mymin,& mymax);
	//printf ("ud: after: min/max %f %f \n",mymin,mymax);
	//printf ("Empty matrix %d\n",frame.empty());
	int res = Tr->tracker->update(frame,box );
	//printf ("upaate: found? %d\n",res);
	//printf ("upaate: type? %d\n",frame.type());
	cv::rectangle( frame, box, cv::Scalar( 255, 0, 0 ), 2, 1 );
	cv::imshow("ud",frame);
	mw->mat=frame;
	cv::waitKey(10);
	//printf ("ut: box %d %d \n",box.x ,box.y);
	//printf ("ut: box %d %d \n",box.width ,box.height);
	roi->x=box.x;
	roi->y=box.y;
	roi->height=box.height;
	roi->width=box.width;
	return res;
}

int deleteMat(MatWrapper * wrapper) {
	delete wrapper;
	return 1;
}

MatWrapper * emptyMW () {
	return new MatWrapper;
}

MatWrapper * newMat (const ptrdiff_t cols, const ptrdiff_t rows, const int type, int planes, void * data) {
	MatWrapper *mw = new MatWrapper;
	mw->mat = cv::Mat(rows, cols, get_ocvtype(type,planes), data);
	return mw;
}

ptrdiff_t cols (MatWrapper * mw) {
	return mw->mat.cols;
}

ptrdiff_t rows (MatWrapper * mw) {
	return mw->mat.rows;
}

void *matData (MatWrapper * mw) {
	return mw->mat.ptr();
}

int cwtype (MatWrapper * mw, int * pdltype) {
	int type = pdltype [0]; //
	if (type >=0) {
		type= get_ocvtype(pdltype[0],CV_MAT_CN(mw->mat.type()));
		if  ( type != mw->mat.type())  {
			mw->mat.convertTo(mw->mat,type);
		}
	} else {
		pdltype[0]=get_pdltype(mw->mat.type());
	}
	return mw->mat.type();
}

const char *vDims(MatWrapper *wrapper, ptrdiff_t *t, ptrdiff_t *l, ptrdiff_t *c, ptrdiff_t *r) {
	*c = wrapper->mat.cols;
	*r = wrapper->mat.rows;
	*t = wrapper->mat.type();
	*l = wrapper->mat.channels();
	return NULL;
}

struct VideoWriterWrapper {
	cv::VideoWriter writer;
};

VideoWriterWrapper *newVideoWriter() {
	return new VideoWriterWrapper;
}

int deleteVideoWriter(VideoWriterWrapper * wrapper) {
	delete wrapper;
	return 1;
}

const char *openVideoWriter(VideoWriterWrapper *wrapper, const char *name, const char *code, double fps, int width, int height, char iscolor) {
	if (!wrapper->writer.open(
	  name,
	  cv::VideoWriter::fourcc(code[0],code[1],code[2],code[3]),
	  fps,
	  cv::Size(width, height),
	  iscolor
	)) return "Error opening video write";
	return NULL;
}

void writeVideoWriter(VideoWriterWrapper *wrapper, MatWrapper *mw) {
	wrapper->writer.write(mw->mat);
}

struct VideoCaptureWrapper {
	cv::VideoCapture capture;
};

VideoCaptureWrapper *newVideoCapture() {
	return new VideoCaptureWrapper;
}

int deleteVideoCapture(VideoCaptureWrapper * wrapper) {
	delete wrapper;
	return 1;
}

const char *openVideoCaptureURI(VideoCaptureWrapper *wrapper, const char *uri) {
	wrapper->capture.open( uri );
	if (!wrapper->capture.isOpened()) return "Error opening video capture";
	return NULL;
}

ptrdiff_t framecountVideoCapture(VideoCaptureWrapper *wrapper) {
	return wrapper->capture.get(cv::CAP_PROP_FRAME_COUNT);
}

bool readVideoCapture(VideoCaptureWrapper *wrapper, MatWrapper *mw) {
	return wrapper->capture.read(mw->mat);
}
EOF

print $fc $tstr;
print $fc $rstr;

print $fh sprintf qq{#line %d "%s"\n}, __LINE__ + 2,  __FILE__;
print $fh <<'EOF';
#ifndef OPENCV_WRAPPER_H
#define OPENCV_WRAPPER_H

#ifdef __cplusplus
#include <vector>
#include <opencv2/opencv.hpp>
struct MatWrapper
{
        cv::Mat mat;
};
#endif

#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>

typedef struct bBox{
	int x; int y; int width; int height;
} bBox;

typedef struct MatWrapper  MatWrapper ;
ptrdiff_t rows (MatWrapper * mw) ;
ptrdiff_t cols (MatWrapper * mw) ;
void *matData(MatWrapper * mw);
int cwtype (MatWrapper * mw, int * pdltype) ;
const char *vDims(MatWrapper *wrapper, ptrdiff_t *t, ptrdiff_t *l, ptrdiff_t *c, ptrdiff_t *r);

typedef struct VideoWriterWrapper VideoWriterWrapper;
VideoWriterWrapper *newVideoWriter();
int deleteVideoWriter (VideoWriterWrapper *);
const char *openVideoWriter(VideoWriterWrapper *wrapper, const char *name, const char *code, double fps, int width, int height, char iscolor);
void writeVideoWriter(VideoWriterWrapper *wrapper, MatWrapper *mw);

typedef struct VideoCaptureWrapper VideoCaptureWrapper;
VideoCaptureWrapper *newVideoCapture();
int deleteVideoCapture (VideoCaptureWrapper *);
const char *openVideoCaptureURI(VideoCaptureWrapper * Tr, const char *uri);
ptrdiff_t framecountVideoCapture(VideoCaptureWrapper *wrapper);
bool readVideoCapture(VideoCaptureWrapper *wrapper, MatWrapper *mw);

typedef struct TrackerWrapper TrackerWrapper;
TrackerWrapper * newTracker (int tracker_type);
int  deleteTracker (TrackerWrapper *);
int initTracker(TrackerWrapper * Tr, MatWrapper * frame, bBox * box );
int updateTracker(TrackerWrapper *, MatWrapper *, bBox * box);

MatWrapper * newMat (const ptrdiff_t cols, const ptrdiff_t rows, const int type, const int planes, void * data);
MatWrapper * emptyMW ();
int deleteMat(MatWrapper * wrapper);

int get_pdltype(const int cvtype);
int get_ocvtype(const int datatype,const int planes);
EOF

for my $func (@funclist) {
	my ($hstr,$cstr) = gen_code( @$func );
	print $fh $hstr;
	print $fc $cstr;
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

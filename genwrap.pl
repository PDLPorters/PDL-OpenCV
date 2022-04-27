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
	my $bs = PDL::Core::howbig($type);
	my $s = 8*$bs;
	$tstr_l.="\tcase $nt :
		//printf(\"cv type %d\\n\",CV_$s${tt}C(planes));
		return CV_$s${tt}C(planes); break;\n";
	$mstr_l.="\tcase $nt : $ct * fdata = ($ct * ) data; break;\n";
	$rstr_l.="\tcase CV_$s$tt : t = $nt; break;\n";
	$gstr_l.="\t$ct * ${ts}data=reinterpret_cast <$ct *>(rdata);\n
	\t\t/*ptrdiff_t fs = $s * ch * lins * cols;*/ \n ";
	$gstr_l2.="\t\t\tcase CV_$s$tt : ${ts}data[(j*cols+i)*ch+c+v*$bs*ch*lins*cols] = frame.ptr<$ct>(j)[ch*i+c];\n
	//printf(\"MatAt data at frame %d i %d j %d ch %d: %d / %d\\n\",v,i, j, c,frame.ptr<$ct>(j)[ch*i+c],${ts}data[(j*cols+i)*ch+c+v*$bs*ch*lins*cols] );
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

my $gstr="
int getDataCopy(const MatWrapper * mw,void * rdata, ptrdiff_t vl) {
	/*
	printf(\"getDataCopy: vl %d\\n\",vl);
	printf(\"getDataCopy: rdata %p\\n\",rdata);
	*/
	ptrdiff_t lins=mw->mat.rows;
	ptrdiff_t cols=mw->mat.cols;
	int cvtype=mw->mat.type();
	int ch=mw->mat.channels();
	Mat frame;
	uchar depth = CV_MAT_DEPTH(cvtype); //    type & CV_MAT_DEPTH_MASK;
	printf(\"getDataCopy: cvtype %d\\n\",depth);
	printf(\"getDataCopy: vl %td\\n\",vl);
	if (vl > 0) {
	try {vl=mw->vmat.size(); } catch (...) { vl=1;} // default to 0 if not a vector
	//printf(\"getDataCopy: vl %d\\n\",vl);
	} else vl = 1;
	$gstr_l
	//printf(\"getDataCopy: mw->mat %p\\n\",mw->mat);
	//printf(\"getDataCopy: mw->vmat[0] %p\\n\",mw->vmat[0]);
	for (ptrdiff_t v = 0; v<vl; v ++ ) { //  iterate over vmax;
		frame=mw->vmat[v];
		//printf(\"frame %d cols %d rows %d channels %d\\n\",v,frame.cols,frame.rows,frame.channels());
		/*
		int i=360;
		int j=138;
		int c=1;
		printf(\"MatAt data at frame %d i %d j %d ch %d: %d / %d\\n\",v,i, j, c,frame.ptr<unsigned char>(j)[ch*i+c],Bdata[(j*cols+i)*ch+c+v*1*ch*lins*cols] );
		*/
		for ( ptrdiff_t i = 0; i<cols; i++ ) {
			for ( ptrdiff_t j = 0; j<lins; j++ ) {
				for (int c = 0; c<ch; c++) {
					switch (depth) {
					$gstr_l2
					}
				}
			}
		}
		/*
		printf(\"frame %d cols %d rows %d channels %d\\n\",v,frame.cols,frame.rows,frame.channels());
		i=360;
		j=138;
		c=1;
		printf(\"after data at frame %d i %d j %d ch %d: %d / %d\\n\",v,i, j, c,frame.ptr<unsigned char>(j)[ch*i+c],Bdata[(j*cols+i)*ch+c+v*1*ch*lins*cols] );
		*/
	}
	return get_pdltype(cvtype);
}
";

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
using namespace cv;
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
		//tracker = TrackerBoosting::create();
	if (trackerType == "MIL")
		tracker = TrackerMIL::create();
	if (trackerType == "KCF")
		tracker = TrackerKCF::create();
	/*if (trackerType == "TLD")
		tracker = TrackerTLD::create();
	if (trackerType == "MEDIANFLOW")
		tracker = TrackerMedianFlow::create();*/
	if (trackerType == "GOTURN")
		tracker = TrackerGOTURN::create();
	//if (trackerType == "MOSSE")
		//tracker = TrackerMOSSE::create();
	if (trackerType == "CSRT")
		tracker = TrackerCSRT::create();
	// Ptr<Tracker> tracker = TrackerKCF::create();
	TrackerWrapper * Tr= new TrackerWrapper;
	Tr->tracker = tracker;
	//printf ("init tracker done.\n");
	return Tr;
}

int deleteTracker(TrackerWrapper * wrapper) {
	delete wrapper;
	return 1;
}

int deleteMat(MatWrapper * wrapper) {
	delete wrapper;
	return 1;
}

MatWrapper * emptyMW () {
	MatWrapper * mw = new MatWrapper;
	mw->mat=Mat();
	mw->dp=mw->mat.data;
	mw->vmat = vector<Mat>(1,mw->mat);
	return mw;
}

MatWrapper * emptyMat (const ptrdiff_t cols=1, const ptrdiff_t rows=1, const int type=CV_32FC1 ) {
	MatWrapper * mw = new MatWrapper;
	//printf ("rows %d cols %d\n",rows,cols);
	//printf ("rs %d cs %d\n",rows,cols);
	Mat frame;
	try {
		frame=Mat(rows, cols,CV_32FC1);
	} catch (...) { printf ("Mat could not be created.\n"); }
	//printf ("rows %d cols %d\n",frame.rows,frame.cols);
	//printf ("rows %d cols %d\n",frame.rows,frame.cols);
	//printf("empty mat %d\n", MatAt (mw,32,48) );
	mw->mat=  frame;
	mw->vmat=vector<Mat>(1,frame);
	//printf("empty mat %d\n", MatAt (mw,32,48) );
	//printf ("mw -> rows %d cols %d\n",mw->mat.rows,mw->mat.cols);
	return mw;
}

int newMat2 (MatWrapper * mw,const ptrdiff_t cols, const ptrdiff_t rows, const int type, void * data) {
	cv::Mat frame,norm;
	try { mw->mat.cols; } catch (...) { mw = new MatWrapper; } // if undefined, return new object.

	//printf ("data type %d\n",type);
	if ((type == CV_32FC1) || (type == CV_32FC3)) {
		float * fdata = (float * ) data;
		frame=Mat (rows, cols, type, fdata);
		//printf("set float data.\n");
	}
	//frame.data =(uchar*) data;
	normalize(frame,norm, 1,0, NORM_MINMAX) ; //, -1,CV_8UC1);
	//printf("norm.\n");
	//normalize(image1, dst, 255, 230, NORM_MINMAX,-1, noArray());
	mw->mat =  norm;
	mw->vmat =  vector<Mat>(1,norm);
	mw->dp=norm.data;
	//printf("assign. type %d\n",norm.type());
	return  1;
}

MatWrapper * newMat (const ptrdiff_t cols, const ptrdiff_t rows, const int type, int planes, void * data) {
	cv::Mat frame,norm;
	int cvtype = get_ocvtype(type,planes);
	printf ("newMat data type mapped %d(%d): %d data=%p\n",type,planes, cvtype, data);
	//if (type == CV_32FC) ) {
		//float * fdata = (float * ) data;
		frame=Mat (rows, cols, cvtype, data); //.clone();
		//printf("set float data.\n");
	//}
	//frame.data =(uchar*) data;
	MatWrapper * mw = new MatWrapper;
	//normalize(frame,frame, 1,0, NORM_MINMAX) ; //, -1,CV_8UC1);
	//printf ("norm 0 0 (newMat) %f\n",frame.at<float>(0,0));
	//normalize(image1, dst, 255, 230, NORM_MINMAX,-1, noArray());
	mw->mat =  frame;
	mw->vmat  = vector<Mat>(1, frame);
	mw->dp=frame.data;
	//printf ("at 0 0 (newMat) %f\n",MatAt(mw,0,0));
	//printf ("mat type %d \n",mw->mat.type());
	return  mw;
}

int newVector(MatWrapper * mw,const ptrdiff_t vs,const ptrdiff_t cols, const ptrdiff_t rows, const int type, const int planes, void * data,ptrdiff_t size) {
	int cvtype=get_ocvtype(type,planes);
	vector<Mat> mv(vs);
	//printf ("rows %d cols %d\n",rows,cols);
	//printf ("type %d planes %d\n",type,planes);
	for (ptrdiff_t j=0;j<vs;j++) {
		Mat frame = Mat(rows,cols,cvtype,reinterpret_cast<char *>(data) + j*size);
		//cout<<"size (frame) "<< frame.size() << endl;
		//mv.push_back(frame);
		mv[j]=frame;
		//cout<<"size (push_back) "<< mv[j].size() << endl;
	}
	mw->vmat = mv;
	mw->mat = mv[0];
	mw->dp=data;
	//cout<<"size [0]"<< mw->vmat[0].size() << endl;
	return 1;
}
void * getData (MatWrapper * frame) {
	if (frame->mat.data != frame->dp) frame->dp=frame->mat.data;
	return frame->mat.data;
}


ptrdiff_t cols (MatWrapper * mw, ptrdiff_t cols) {
	//printf ("cols(): %d, %d\n",mw->mat.cols,cols);
	if ( cols>=0 ) { mw->mat.cols=cols; }
	//printf ("cols(): after set %d\n",mw->mat.cols);
	return mw->mat.cols;
}

ptrdiff_t rows (MatWrapper * mw, ptrdiff_t rows) {
	if ( rows>=0 ) mw->mat.rows=rows;
	return mw->mat.rows;
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

int planes (MatWrapper * mw) {
	return mw->mat.channels();
}

int setMat (MatWrapper * mw, void * data, const int type, const ptrdiff_t rows, const ptrdiff_t cols ){
	mw->mat.rows = rows;
	mw->mat.cols = cols;
	if (type >=0 && type != mw->mat.type())  {
		mw->mat.convertTo(mw->mat,type);
	}
	mw->mat.data=(uchar *)data;
	return 1;
}

int vWrite(MatWrapper * mw,char * name, char * code, double fps) {
	string str;
	str=string(name);
	cout<<"size "<< mw->vmat[0].size() << endl;
	VideoWriter cap(str,VideoWriter::fourcc(code[0],code[1],code[2],code[3]),fps,mw->vmat[0].size(),mw->vmat[0].channels()-1);
        if ( ! cap.isOpened() )
        {
                cout << "--(!)Error opening video capture\n";
                return -1;
        }
        for (auto it = begin (mw->vmat); it != end (mw->vmat); ++it) {
		cap.write(*it);
	}
	cap.release();
	return 1;
}

ptrdiff_t vRead(MatWrapper * mw,char * name) {
	string str;
	str=string(name);
	VideoCapture cap;
	cap.open( str );
        if ( ! cap.isOpened() )
        {
                cout << "--(!)Error opening video capture\n";
                return -1;
        }
	vector <Mat> video;
	ptrdiff_t j=0;
	Mat frame;
	for ( ;; ) {
		cap >> frame;
		if(frame.rows==0 || frame.cols==0)
                        break;
		video.push_back(frame.clone());
		j++;
	}
	Mat * mp = & video[0];
	mw->vmat= video;
	mw->mat=video[0];
	mw->dp=mp->data;
	return j;
}

const char *vDims(char * name, ptrdiff_t *t, ptrdiff_t *l, ptrdiff_t *c, ptrdiff_t *r, ptrdiff_t *f) {
	string str = string(name);
	VideoCapture cap;
	cap.open( str );
        if (!cap.isOpened()) return "Error opening video capture";
	*f = cap.get(CAP_PROP_FRAME_COUNT);
	*c = cap.get(CAP_PROP_FRAME_WIDTH);
	*r = cap.get(CAP_PROP_FRAME_HEIGHT);
	Mat frame;
	cap >> frame;
	*t = frame.type();
	*l = frame.channels();
	return NULL;
}

ptrdiff_t vectorSize (MatWrapper * mw, ptrdiff_t vl) {
	if (vl>=0) mw->vmat.reserve(vl);
	try {vl=mw->vmat.size(); } catch (...) { }
	return  vl;
}

int initTracker(TrackerWrapper * Tr, MatWrapper * mw, bBox * box ){
	Rect roi;
	Mat frame;
	roi.x=box->x;
	roi.y=box->y;
	roi.height=box->height;
	roi.width=box->width;
	double mymin,mymax;
	minMaxIdx(mw->mat, & mymin,& mymax);
	double scale = 256/mymax;
	mw->mat.convertTo(frame,CV_8UC3,scale);
	if(frame.channels()==1) cvtColor(frame,frame,COLOR_GRAY2RGB);
	if (roi.x == 0) {
		namedWindow("ud",WINDOW_NORMAL);
		roi=selectROI("ud",frame,true,false);
		destroyWindow("ud");
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
	Rect box;
#else
	Rect2d box;
#endif
	Mat frame;
	double mymin,mymax;
	minMaxIdx(mw->mat, & mymin,& mymax);
	double scale = 256/mymax;
	mw->mat.convertTo(frame,CV_8UC3,scale);
	printf ("updateTracker matrix c=%d r=%d\n", frame.cols, frame.rows); fflush(stdout);
	if(frame.channels()==1) cvtColor(frame,frame,COLOR_GRAY2RGB);
	//printf ("ud: min/max %f %f \n",mymin,mymax);
	/*
	if ( mw->mat.type() > 4 ) {
		normalize(mw->mat,frame, 1,0, NORM_MINMAX) ; //, -1,CV_8UC1);
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
	rectangle( frame, box, Scalar( 255, 0, 0 ), 2, 1 );
	imshow("ud",frame);
	mw->mat=frame;
	waitKey(10);
	//printf ("ut: box %d %d \n",box.x ,box.y);
	//printf ("ut: box %d %d \n",box.width ,box.height);
	roi->x=box.x;
	roi->y=box.y;
	roi->height=box.height;
	roi->width=box.width;
	return res;
}

int showTracker (MatWrapper * mw, bBox * box) {
	Rect roi;
	roi.x=box->x;
	roi.y=box->y;
	roi.height=box->height;
	roi.width=box->width;
	rectangle( mw->mat, roi, Scalar( 255, 0, 0 ), 2, 1 );
	return 1;
}

int cv_init() {
	return 1;
}
EOF

print $fc $tstr;
print $fc $rstr;
print $fc $gstr;
print $fc $astr;

print $fh <<'EOF';
#ifndef OPENCV_WRAPPER_H
#define OPENCV_WRAPPER_H

#ifdef __cplusplus
#include <vector>
#include <opencv2/opencv.hpp>
struct MatWrapper
{
        cv::Mat mat;
        void * dp;
        std::vector<cv::Mat> vmat;
};
#endif

#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>

int  cv_init();
typedef struct TrackerWrapper TrackerWrapper;
struct TrackerWrapper * newTracker (int tracker_type);
int  deleteTracker (struct TrackerWrapper *);

typedef struct bBox{
	int x; int y; int width; int height;
} bBox;

typedef struct MatWrapper  MatWrapper ;
ptrdiff_t rows (MatWrapper * mw, ptrdiff_t rows) ;
ptrdiff_t cols (MatWrapper * mw, ptrdiff_t cols) ;
int cwtype (MatWrapper * mw, int * pdltype) ;
int planes (MatWrapper * mw ) ;
ptrdiff_t vRead(MatWrapper * mw,char * name);
const char *vDims(char * name, ptrdiff_t *t, ptrdiff_t *l, ptrdiff_t *c, ptrdiff_t *r, ptrdiff_t *f);
int vWrite(MatWrapper * mw,char * name, char * code, double fps) ;

int newVector(MatWrapper * mw,const ptrdiff_t vs,const ptrdiff_t cols, const ptrdiff_t rows, const int type, const int planes, void * data,const ptrdiff_t size);
ptrdiff_t vectorSize (MatWrapper * mw, ptrdiff_t size) ;
MatWrapper * newMat (const ptrdiff_t cols, const ptrdiff_t rows, const int type, const int planes, void * data);
MatWrapper * emptyMW ();
int deleteMat(MatWrapper * wrapper);
void * getData (MatWrapper * Mat);
int getDataCopy(const MatWrapper * frame,void * data, ptrdiff_t vl);
int setMat (MatWrapper * Mat, void * data, const int type, const ptrdiff_t rows, const ptrdiff_t cols);
int  MatAt (const MatWrapper * mw,const ptrdiff_t x,const ptrdiff_t y,void * data);

int initTracker(TrackerWrapper * Tr, MatWrapper * frame, bBox * box );
int updateTracker(TrackerWrapper *, MatWrapper *, bBox * box);
int showTracker (MatWrapper * frame, bBox * roi) ;

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

#include <opencv2/opencv.hpp>
#include <opencv2/tracking.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include "opencv_wrapper.h"
#include "maptypes.h"
using namespace std;
using namespace cv;
/* use C name mangling */
#ifdef __cplusplus
extern "C" {
#endif

struct TrackerWrapper
{
	cv::Ptr<cv::Tracker> tracker; 
} ;


/*
int map_type(char * rtype, int planes=1, long double scaletype=1) {
	int cvtype,so;
	if (rtype ==  "ushort") {
		so=sizeof(short);
		cvtype=CV_16UC(planes);
		scaletype = 32768;
		//grayIma=rff_us( file,cols,rows,cvtype,planes,so);
		//cout<< so << " "<<sizeof(unsigned short);
		//cout<<"point "<<(int)grayIma.at<unsigned short>(2,1)<<endl;
	}
	if (rtype == "short") {
		so=sizeof(short);
		typedef short imdata_t;
		cvtype=CV_16SC(planes);
		scaletype=65536;  
		//grayIma=rff_s(file,cols,rows,cvtype,planes,so);
	}
	if (rtype == "long") {
		so=sizeof(long);
		cvtype=CV_32SC(planes);
		scaletype=65536L/2*65536;
		//grayIma=rff_l(file,cols,rows,cvtype,planes,so);
	}
	if (rtype ==  "float") {
		so=sizeof(float);
		cvtype=CV_32FC(planes);
		//grayIma=rff_f(file,cols,rows,cvtype,planes,so);
	}
	if (rtype == "double") {
		so=sizeof(double);
		cvtype=CV_64FC(planes);
		//grayIma=rff_d(file,cols,rows,cvtype,planes,so);
	}
	if (rtype == "byte") {
		so=sizeof(char);
		cvtype=CV_8UC(planes);
		scaletype=256;
		//grayIma=rff_b(file,cols,rows,cvtype,planes,so);
	}
	return cvtype;
}
*/

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

/* struct MatWrapper {
	cv::Mat mat;
	void * dp;
};
*/
int deleteMat(MatWrapper * wrapper) {
	delete wrapper;
	return 1;
}
void MatSize (const MatWrapper * Mat, int * cols, int * rows)
{
	(*cols) = Mat->mat.cols;
	(*rows) = Mat->mat.rows;
}

float MatAt (const MatWrapper * mw,const int x,const int y) {
	printf("MatAt: data pointer %p\n",mw->mat.data);
	float f =mw->mat.at<float>(x,y);
	printf("MatAt x/y %d %d: %f\n",x,y, f);
	return f;
}
MatWrapper * emptyMW () {
	MatWrapper * mw = new MatWrapper;
	return mw;
}
	
MatWrapper * emptyMat (const int cols=1, const int rows=1, const int type=CV_32FC1 ) {
//int emptyMat (MatWrapper * mw,const int cols, const int rows, const int type ) {
	MatWrapper * mw = new MatWrapper;
	printf ("rows %d cols %d\n",rows,cols);
	printf ("rs %d cs %d\n",rows,cols);
	Mat frame;
	try {
		frame=Mat(rows, cols,CV_32FC1);
	} catch (...) { printf ("Mat could not be created.\n"); }
	//printf ("rows %d cols %d\n",frame.rows,frame.cols);
	printf ("rows %d cols %d\n",frame.rows,frame.cols);
	//printf("empty mat %d\n", MatAt (mw,32,48) );
	mw->mat=  frame; 
	//printf("empty mat %d\n", MatAt (mw,32,48) );
	printf ("mw -> rows %d cols %d\n",mw->mat.rows,mw->mat.cols);
	return mw;
}

int newMat2 (MatWrapper * mw,const int cols, const int rows, const int type, void * data) {
	cv::Mat frame,norm;
	try { mw->mat.cols; } catch (...) { mw = new MatWrapper; } // if undefined, return new object.

	printf ("data type %d\n",type);
	if ((type == CV_32FC1) || (type == CV_32FC3)) {
		float * fdata = (float * ) data;
		frame=Mat (cols, rows, type, fdata);
		printf("set float data.\n");
	}
	//printf ("at 48 48 (newMat) %f\n",frame.at<float>(48,48));
	//frame.data =(uchar*) data;
	normalize(frame,norm, 1,0, NORM_MINMAX) ; //, -1,CV_8UC1);
	printf("norm.\n");
	//normalize(image1, dst, 255, 230, NORM_MINMAX,-1, noArray());
	mw->mat = norm;
	mw->dp=norm.data;
	printf("assign.\n");
	//printf ("mw->at 48 48 (newMat) %f\n",mw->mat.at<float>(48,48));
	return  1;
}

MatWrapper * newMat (const int cols, const int rows, const int type, int planes, void * data) {
	cv::Mat frame,norm;
	int cvtype = get_ocvtype(type,planes); 
	printf ("newMat data type mapped %d(%d): %d\n",type,planes, cvtype);
	//if (type == CV_32FC) ) {
		//float * fdata = (float * ) data;
		frame=Mat (rows, cols, type, data).clone();
		printf("set float data.\n");
	//}
	printf ("at 0 0 (newMat) %f\n",frame.at<float>(0,0));
	//frame.data =(uchar*) data;
	MatWrapper * mw = new MatWrapper;
	//normalize(frame,frame, 1,0, NORM_MINMAX) ; //, -1,CV_8UC1);
	printf ("frame 0 0 (newMat) %f\n",frame.at<float>(0,0));
	//printf ("norm 0 0 (newMat) %f\n",frame.at<float>(0,0));
	//normalize(image1, dst, 255, 230, NORM_MINMAX,-1, noArray());
	mw->mat = frame;
	mw->dp=frame.data;
	printf ("mw->at 0 0 (newMat) %f\n",mw->mat.at<float>(0,0));
	return  mw;
}
void * getData (MatWrapper * frame) {
	if (frame->mat.data != frame->dp) frame->dp=frame->mat.data;
	return frame->mat.data;
}

int getDataCopy(const MatWrapper * frame,float * data) {
	size_t lins=frame->mat.rows;
	size_t cols=frame->mat.cols;
	for ( size_t i = 0; i<lins; i++ ) {
		for ( size_t j = 0; j<cols; j++ ) {
			data[i*cols+j] = frame->mat.at<float>(i,j);
		}
	}
	return 1;
}
int cols (MatWrapper * mw, int cols) {
	//printf ("cols(): %d\n",mw->mat.cols);
	if ( cols>=0 ) mw->mat.cols=cols;
	//printf ("cols(): %d\n",mw->mat.cols);
	return mw->mat.cols;
}

int rows (MatWrapper * mw, int rows) {
	if ( rows>=0 ) mw->mat.rows=rows;
	return mw->mat.rows;
}

int type (MatWrapper * mw, int type) {
	if (type >=0 && type != mw->mat.type())  {
		mw->mat.convertTo(mw->mat,type);
	}
	return mw->mat.type();
}

int setMat (MatWrapper * frame, void * data, const int type, const int rows, const int cols ){
	frame->mat.rows = rows;
	frame->mat.cols = cols;
	if (type >=0 && type != frame->mat.type())  {
		frame->mat.convertTo(frame->mat,type);
	}
	frame->mat.data=(uchar *)data;	
	return 1;
}
int setData (MatWrapper * frame, void * data, const int type=0 ){
	if (type && type != frame->mat.type())  {
		frame->mat.convertTo(frame->mat,type);
		printf("Converting\n");
	}
	frame->mat.data=(uchar *)data;	
	printf ("set_data (at 0, 0) %f\n",MatAt(frame,0,0));
	return 1;
}

int init_tracker(TrackerWrapper * Tr, MatWrapper * frame, bBox * box ){
	Rect roi;
	roi.x=box->x;
	roi.y=box->y;
	roi.height=box->height;
	roi.width=box->width;
	//imshow("Image ",frame->mat);
	//printf("ROI x %d y %d width %d height %d\n",roi.x,roi.y,roi.width,roi.height);
	//printf("ROI x %d y %d width %d height %d\n",box->x,box->y,box->width,box->height);
	if (roi.x == 0) {
		namedWindow("tracker",WINDOW_NORMAL);
		roi=selectROI("tracker",frame->mat,true,false);
	}
	//printf("ROI x %d y %d width %d height %d\n",roi.x,roi.y,roi.width,roi.height);
	//printf ("at 48 48 (init_tracker %f\n",frame->mat.at<float>(48,48));
	box->x=roi.x;
	box->y=roi.y;
	box->width=roi.width;
	box->height=roi.height;
	//printf("ROI x %d y %d width %d height %d\n",box->x,box->y,box->width,box->height);
	Tr->tracker->init(frame->mat,roi );
	//printf("ROI x %d y %d width %d height %d\n",roi.x,roi.y,roi.width,roi.height);
	//printf("ROI x %d y %d width %d height %d\n",box->x,box->y,box->width,box->height);
	return 1;
}
int update_tracker(TrackerWrapper * Tr, MatWrapper * frame, bBox * roi) {
	Rect box;
	Tr->tracker->init(frame->mat,box );
	Tr->tracker->update(frame->mat,box );
	roi->x=box.x;
	roi->y=box.y;
	roi->height=box.height;
	roi->width=box.width;
	return 1;
}

int show_tracker (MatWrapper * frame, bBox * box) {
	Rect roi;
	roi.x=box->x;
	roi.y=box->y;
	roi.height=box->height;
	roi.width=box->width;
	rectangle( frame->mat, roi, Scalar( 255, 0, 0 ), 2, 1 );
	return 1;
}

int cv_init() {
	/*
	cvT.u8c3 = CV_8UC3;
	cvT.u8c1 = CV_8UC1;
	cvT.f32c3 = CV_32FC3;
	cvT.f32c1 = CV_32FC1;
	printf ("cvt.f32c3 %d.\n",cvT.f32c3);
	printf ("tw_init done.\n");
	*/
	return 1;
}

#ifdef __cplusplus
}
#endif




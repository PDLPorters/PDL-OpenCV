#include <opencv2/opencv.hpp>
#include <opencv2/tracking.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include "tracker_wrapper.h"
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
TrackerWrapper * newTracker(int trackerNumber) {
	string trackerTypes[8] = {"BOOSTING", "MIL", "KCF", "TLD","MEDIANFLOW", "GOTURN", "MOSSE", "CSRT"};
	string trackerType = trackerTypes[trackerNumber];
	printf ("init tracker \n");
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
	printf ("init tracker done.\n");
	return Tr;
}

int deleteTracker(TrackerWrapper * wrapper) {
	delete wrapper;
	return 1;
}

struct MatWrapper {
	cv::Mat mat;
};

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
	printf("MatAt: rows %d",mw->mat.rows);
	return mw->mat.at<float>(x,y);
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
		frame=Mat (rows, cols, type, fdata);
		printf("set float data.\n");
	}
	printf ("at 48 48 (newMat) %f\n",frame.at<float>(48,48));
	//frame.data =(uchar*) data;
	normalize(frame,norm, 1,0, NORM_MINMAX) ; //, -1,CV_8UC1);
	printf("norm.\n");
	//normalize(image1, dst, 255, 230, NORM_MINMAX,-1, noArray());
	mw->mat = norm;
	printf("assign.\n");
	printf ("mw->at 48 48 (newMat) %f\n",mw->mat.at<float>(48,48));
	return  1;
}


MatWrapper * newMat (const int cols, const int rows, const int type, void * data) {
	cv::Mat frame,norm;

	printf ("data type %d\n",type);
	if ((type == CV_32FC1) || (type == CV_32FC3)) {
		float * fdata = (float * ) data;
		frame=Mat (rows, cols, type, fdata);
		printf("set float data.\n");
	}
	printf ("at 48 48 (newMat) %f\n",frame.at<float>(48,48));
	//frame.data =(uchar*) data;
	MatWrapper * mw = new MatWrapper;
	normalize(frame,norm, 1,0, NORM_MINMAX) ; //, -1,CV_8UC1);
	//normalize(image1, dst, 255, 230, NORM_MINMAX,-1, noArray());
	mw->mat = norm;
	printf ("mw->at 48 48 (newMat) %f\n",mw->mat.at<float>(48,48));
	return  mw;
}

void * getData (const MatWrapper * frame) {
	return frame->mat.data;
}
int setMat (MatWrapper * frame, void * data, const int type, const int rows, const int cols ){
	frame->mat.rows = rows;
	frame->mat.cols = cols;
	if (type && type != frame->mat.type())  {
		frame->mat.convertTo(frame->mat,type);
	}
	frame->mat.data=(uchar *)data;	
	return 1;
}
int setData (MatWrapper * frame, void * data, const int type=0 ){
	if (type && type != frame->mat.type())  {
		frame->mat.convertTo(frame->mat,type);
	}
	frame->mat.data=(uchar *)data;	
	return 1;
}

int init_tracker(TrackerWrapper * Tr, MatWrapper * frame, bBox * box ){
	Rect roi;
	roi.x=box->x;
	roi.y=box->y;
	roi.height=box->height;
	roi.width=box->width;
	//imshow("Image ",frame->mat);
	printf("ROI x %d y %d width %d height %d\n",roi.x,roi.y,roi.width,roi.height);
	printf("ROI x %d y %d width %d height %d\n",box->x,box->y,box->width,box->height);
	if (roi.x == 0) {
		namedWindow("tracker",WINDOW_NORMAL);
		roi=selectROI("tracker",frame->mat,true,false);
	}
	printf("ROI x %d y %d width %d height %d\n",roi.x,roi.y,roi.width,roi.height);
	printf ("at 48 48 (init_tracker %f\n",frame->mat.at<float>(48,48));
	box->x=roi.x;
	box->y=roi.y;
	box->width=roi.width;
	box->height=roi.height;
	printf("ROI x %d y %d width %d height %d\n",box->x,box->y,box->width,box->height);
	Tr->tracker->init(frame->mat,roi );
	printf("ROI x %d y %d width %d height %d\n",roi.x,roi.y,roi.width,roi.height);
	printf("ROI x %d y %d width %d height %d\n",box->x,box->y,box->width,box->height);
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
	cvT.u8c3 = CV_8UC3;
	cvT.u8c1 = CV_8UC1;
	cvT.f32c3 = CV_32FC3;
	cvT.f32c1 = CV_32FC1;
	printf ("tw_init done.\n");
	return 1;
}

#ifdef __cplusplus
}
#endif




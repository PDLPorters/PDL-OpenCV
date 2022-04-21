#include <opencv2/opencv.hpp>
#include <opencv2/tracking.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/videoio.hpp>
#include <opencv2/core/utility.hpp>
#include "opencv_wrapper.h"
#include <opencv2/videoio.hpp>

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
/*
void MatSize (const MatWrapper * Mat, int * cols, int * rows)
{
	cols = & Mat->mat.cols;
	rows = & Mat->mat.rows;
	printf ("cols %d\n",cols[0]);
	printf ("cols %d\n",(*cols));
}
*/

/*
void * MatAt (const MatWrapper * mw,const ptrdiff_t y,const ptrdiff_t x) {
	int type=mw->mat.type();
	printf("MatAt: data pointer %p\n",mw->mat.data);
	//printf("MatAt: data tyep %d\n",type);
	uchar depth = CV_MAT_DEPTH(type); //	type & CV_MAT_DEPTH_MASK;
	uchar chans = 1 + (type >> CV_CN_SHIFT);
	printf ("depth %d chans %d\n",depth,chans);
	Mat frame=mw->mat;
	void * f;
	switch ( depth ) {
		f = & frame.data[frame.channels()*(frame.cols*y + x) + 0];
		case CV_8S:  f =mw->mat.at<char*>(x,y); break;
		case CV_8U:  f =mw->mat.at<unsigned char*>(x,y); break;
		case CV_16U: f =mw->mat.at<unsigned short>(x,y); break;
		case CV_16S: f =mw->mat.at<short>(x,y); break;
		case CV_32S: f =mw->mat.at<long>(x,y); break;
		case CV_32F: f =mw->mat.at<float>(x,y); break;
		case CV_64F: f =mw->mat.at<double>(x,y); break;
	}
	printf("MatAt: f %f\n",f[1]);
	return f;
}
*/

MatWrapper * emptyMW () {
	MatWrapper * mw = new MatWrapper;
	mw->mat=Mat();
	mw->dp=mw->mat.data;
	mw->vmat = vector<Mat>(1,mw->mat);
	return mw;
}
	
MatWrapper * emptyMat (const ptrdiff_t cols=1, const ptrdiff_t rows=1, const int type=CV_32FC1 ) {
//int emptyMat (MatWrapper * mw,const int cols, const int rows, const int type ) {
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
	//printf ("newMat data type mapped %d(%d): %d\n",type,planes, cvtype);
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
int setData (MatWrapper * mw, void * data, const int type){
	int cvtype=get_ocvtype(type,CV_MAT_CN(mw->mat.type()));
	//printf ("cvt %d t %d\n",cvtype,type); 
	Mat out;
	if (type && cvtype != mw->mat.type())  {
		mw->mat.convertTo(mw->mat,cvtype);
		//printf("Converting\n");
	}
	//mw->mat=out;
	//mw->vmat[0]=out;
	mw->mat.data=(uchar *)data;	
	//printf ("set_data (at 3, 1) %f\n",MatAt(mw,3,1));
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

ptrdiff_t vRead(MatWrapper * mw,char * name /*,void * data*/) {
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
	//	printf ("vread: frame %d\n",j);
		cap >> frame;
		if(frame.rows==0 || frame.cols==0)
                        break;
		//printf ("video %d 360 138 %d %d %d\n",j,frame.ptr<uchar>(368)[138*3+0],frame.ptr<uchar>(368)[13*3+1],frame.ptr<uchar>(368)[138*3+2]);
		video.push_back(frame.clone());
		//printf ("frame %d 360 138: ",j);
		//cout << frame.at<uchar>(368,138)[0]<< endl;
		//printf ("video %d 360 138 %d %d %d\n",j,video[j].ptr<uchar>(368)[138*3+0],video[j].ptr<uchar>(368)[13*3+1],video[j].ptr<uchar>(368)[138*3+2]);
		j++;
	}
	Mat * mp = & video[0];
	mw->vmat= video;
	mw->mat=video[0];
	mw->dp=mp->data;
	int i=0;
	printf ("video %d 360 138 %d %d %d\n",i,video[i].ptr<uchar>(368)[138*3+0],video[i].ptr<uchar>(368)[13*3+1],video[i].ptr<uchar>(368)[138*3+2]);
	/*
	printf ("vread: frame %d\n",j);
	for (ptrdiff_t i =0 ; i<j; i++) {
		printf ("video %d 360 138 %d %d %d\n",i,video[i].ptr<uchar>(368)[138*3+0],video[i].ptr<uchar>(368)[13*3+1],video[i].ptr<uchar>(368)[138*3+2]);
		//printf ("mw %d 360 138 %d %d %d\n",i,mw->vmat[i].at<uchar>(368,138));
	}
	*/
	return j;
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
	Tr->tracker->init(frame,roi );
	//printf("ROI x %d y %d width %d height %d\n",roi.x,roi.y,roi.width,roi.height);
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




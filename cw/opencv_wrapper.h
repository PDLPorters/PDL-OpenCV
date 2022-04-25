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

#ifdef __cplusplus
}
#endif

#endif

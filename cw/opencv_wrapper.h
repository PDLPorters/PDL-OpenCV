
#ifndef OPENCV_WRAPPER_H
#define OPENCV_WRAPPER_H

#ifdef __cplusplus
//#include <opencv2/viz/vizcore.hpp>
extern "C" {
#endif

#include <stddef.h>

/* 
typedef struct cvType {
	int u8c3 ;
        int u8c1 ;
        int f32c3 ;
        int f32c1 ;
} cvType ;
static cvType cvT;
*/
int  cv_init();
typedef struct TrackerWrapper TrackerWrapper;
struct TrackerWrapper * newTracker (int tracker_type);
int  deleteTracker (struct TrackerWrapper *);

typedef struct bBox{  
	int x; int y; int width; int height;
} bBox;
 


typedef struct MatWrapper  MatWrapper ;
/*#ifdef 0 &&__cplusplus
struct MatWrapper 
{
        cv::Mat mat;
        void * dp;

}
;
#else 

#endif
*/
size_t rows (MatWrapper * mw, size_t rows) ;
size_t cols (MatWrapper * mw, size_t cols) ;
int cwtype (MatWrapper * mw, int * pdltype) ;
//int vread(MatWrapper * mw,char * name,void * data);
size_t vectorSize (MatWrapper * mw, size_t size) ;
MatWrapper * newMat (const size_t cols, const size_t rows, const int type, const int planes, void * data);
MatWrapper * emptyMW ();
//MatWrapper * emptyMat (const int cols, const int rows, const int type );
//int newMat2 (MatWrapper * mw,const int cols, const int rows, const int type, void * data);
int deleteMat(MatWrapper * wrapper);
void * getData (MatWrapper * Mat);
int getDataCopy(const MatWrapper * frame,void * data, size_t vl);
int setData (MatWrapper * Mat, void * data, const int type);
int setMat (MatWrapper * Mat, void * data, const int type, const size_t rows, const size_t cols);
//void MatSize (const MatWrapper * Mat, int * cols, int * rows);
double MatAt (const MatWrapper * mw,const size_t x,const size_t y);

int init_tracker(TrackerWrapper * Tr, MatWrapper * frame, bBox * box );
int update_tracker(TrackerWrapper *, MatWrapper *, bBox * box);
int show_tracker (MatWrapper * frame, bBox * roi) ;

#ifdef __cplusplus
}
#endif


#endif // 

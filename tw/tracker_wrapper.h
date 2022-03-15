
#ifndef _CALCULATESHIFT_WRAPPER_H
#define _CALCULATESHIFT_WRAPPER_H

#define CARDIACMOCO_ICE_NAMESPACE offline
#ifdef __cplusplus
#include <opencv2/viz/vizcore.hpp>
extern "C" {
#endif

// #include <opencv2/opencv.hpp>

// 
struct cvType {
	int u8c3 ;
        int u8c1 ;
        int f32c3 ;
        int f32c1 ;
} cvT;

int  cv_init();
//struct cvType cvT;
typedef struct TrackerWrapper TrackerWrapper;
struct TrackerWrapper * newTracker (int tracker_type);
int  deleteTracker (struct TrackerWrapper *);

typedef struct bBox{  
	int x; int y; int width; int height;
} bBox;
 


typedef struct MatWrapper  MatWrapper ;
int rows (MatWrapper * mw, int rows) ;
int cols (MatWrapper * mw, int cols) ;
int type (MatWrapper * mw, int type) ;
MatWrapper * newMat (const int cols, const int rows, const int type, void * data);
MatWrapper * emptyMW ();
MatWrapper * emptyMat (const int cols, const int rows, const int type );
int newMat2 (MatWrapper * mw,const int cols, const int rows, const int type, void * data);
int deleteMat(MatWrapper * wrapper);
void * getData (const MatWrapper * Mat);
int getDataCopy(const MatWrapper * frame,float * data);
int setData (MatWrapper * Mat, void * data, const int type);
int setMat (MatWrapper * Mat, void * data, const int type, const int rows, const int cols);
void MatSize (const MatWrapper * Mat, int * cols, int * rows);
float MatAt (const MatWrapper * mw,const int x,const int y);

int init_tracker(TrackerWrapper * Tr, MatWrapper * frame, bBox * box );
int update_tracker(TrackerWrapper *, MatWrapper *, bBox * box);
int  show_tracker (MatWrapper * frame, bBox * roi) ;

#ifdef __cplusplus
}
#endif


#endif // 


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

int cw_convertTo ( MatWrapper * mw ,  MatWrapper * out, int type) {
int retval;

mw->mat.convertTo ( out->mat, type );

 return retval; 
}
int cw_normalize ( MatWrapper * mw ,  MatWrapper * out, int start, int end, int type) {
int retval;

normalize ( mw->mat,out->mat, start, end, type );

 return retval; 
}

#ifdef __cplusplus
}
#endif


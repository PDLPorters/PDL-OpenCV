

#ifndef GENERATED_CVWRAPPER_H
#define GENERATED_CVWRAPPER_H

#ifdef __cplusplus
#include <opencv2/viz/vizcore.hpp>
extern "C" {
#endif

#include "opencv_wrapper.h"

int cw_convertTo ( MatWrapper * mw ,  MatWrapper * out, int type) ;
int cw_normalize ( MatWrapper * mw ,  MatWrapper * out, int start, int end, int type) ;

#ifdef __cplusplus
}
#endif


#endif // 

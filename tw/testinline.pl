#!perl

package PDL::OpenCV::Generated;

use Inline C => Config =>
           enable => autowrap => LIBS => "-lopencv_wrapper" ; 

use Inline C =>"#include <generated_cvwrapper.h>";

1;

(
['LineSegmentDetector','compareSegments','@brief Draws two groups of lines in blue and red, counting the non overlapping (mismatching) pixels.

    @param size The size of the image, where lines1 and lines2 were found.
    @param lines1 The first group of lines that needs to be drawn. It is visualized in blue color.
    @param lines2 The second group of lines. They visualized in red color.
    @param image Optional image, where the lines will be drawn. The image should be color(3-channel)
    in order for lines1 and lines2 to be drawn in the above mentioned colors.',1,'int',['Size','size','',['/C','/Ref']],['Mat','lines1','',[]],['Mat','lines2','',[]],['Mat','image','Mat()',['/IO']]],
['LineSegmentDetector','detect','@brief Finds lines in the input image.

    This is the output of the default parameters of the algorithm on the above shown image.

    ![image](pics/building_lsd.png)

    @param image A grayscale (CV_8UC1) input image. If only a roi needs to be selected, use:
    `lsd_ptr-\\>detect(image(roi), lines, ...); lines += Scalar(roi.x, roi.y, roi.x, roi.y);`
    @param lines A vector of Vec4f elements specifying the beginning and ending point of a line. Where
    Vec4f is (x1, y1, x2, y2), point 1 is the start, point 2 - end. Returned lines are strictly
    oriented depending on the gradient.
    @param width Vector of widths of the regions, where the lines are found. E.g. Width of line.
    @param prec Vector of precisions with which the lines are found.
    @param nfa Vector containing number of false alarms in the line region, with precision of 10%. The
    bigger the value, logarithmically better the detection.
    - -1 corresponds to 10 mean false alarms
    - 0 corresponds to 1 mean false alarm
    - 1 corresponds to 0.1 mean false alarms
    This vector will be calculated only when the objects type is #LSD_REFINE_ADV.',1,'void',['Mat','image','',[]],['Mat','lines','',['/O']],['Mat','width','Mat()',['/O']],['Mat','prec','Mat()',['/O']],['Mat','nfa','Mat()',['/O']]],
['LineSegmentDetector','drawSegments','@brief Draws the line segments on a given image.
    @param image The image, where the lines will be drawn. Should be bigger or equal to the image,
    where the lines were found.
    @param lines A vector of the lines that needed to be drawn.',1,'void',['Mat','image','',['/IO']],['Mat','lines','',[]]],
['','cvtColor','@brief Converts an image from one color space to another.

The function converts an input image from one color space to another. In case of a transformation
to-from RGB color space, the order of the channels should be specified explicitly (RGB or BGR). Note
that the default color format in OpenCV is often referred to as RGB but it is actually BGR (the
bytes are reversed). So the first byte in a standard (24-bit) color image will be an 8-bit Blue
component, the second byte will be Green, and the third byte will be Red. The fourth, fifth, and
sixth bytes would then be the second pixel (Blue, then Green, then Red), and so on.

The conventional ranges for R, G, and B channel values are:
-   0 to 255 for CV_8U images
-   0 to 65535 for CV_16U images
-   0 to 1 for CV_32F images

In case of linear transformations, the range does not matter. But in case of a non-linear
transformation, an input RGB image should be normalized to the proper value range to get the correct
results, for example, for RGB \\f$\\rightarrow\\f$ L\\*u\\*v\\* transformation. For example, if you have a
32-bit floating-point image directly converted from an 8-bit image without any scaling, then it will
have the 0..255 value range instead of 0..1 assumed by the function. So, before calling #cvtColor ,
you need first to scale the image down:
@code
    img *= 1./255;
    cvtColor(img, img, COLOR_BGR2Luv);
@endcode
If you use #cvtColor with 8-bit images, the conversion will have some information lost. For many
applications, this will not be noticeable but it is recommended to use 32-bit images in applications
that need the full range of colors or that convert an image before an operation and then convert
back.

If conversion adds the alpha channel, its value will set to the maximum of corresponding channel
range: 255 for CV_8U, 65535 for CV_16U, 1 for CV_32F.

@param src input image: 8-bit unsigned, 16-bit unsigned ( CV_16UC... ), or single-precision
floating-point.
@param dst output image of the same size and depth as src.
@param code color space conversion code (see #ColorConversionCodes).
@param dstCn number of channels in the destination image; if the parameter is 0, the number of the
channels is derived automatically from src and code.

@see @ref imgproc_color_conversions',0,'void',['Mat','src','',[]],['Mat','dst','',['/O']],['int','code','',[]],['int','dstCn','0',[]]],
['','logPolar','@brief Remaps an image to semilog-polar coordinates space.

@deprecated This function produces same result as cv::warpPolar(src, dst, src.size(), center, maxRadius, flags+WARP_POLAR_LOG);

@internal
Transform the source image using the following transformation (See @ref polar_remaps_reference_image "Polar remaps reference image d)"):
\\f[\\begin{array}{l}
  dst( \\rho , \\phi ) = src(x,y) \\\\
  dst.size() \\leftarrow src.size()
\\end{array}\\f]

where
\\f[\\begin{array}{l}
  I = (dx,dy) = (x - center.x,y - center.y) \\\\
  \\rho = M \\cdot log_e(\\texttt{magnitude} (I)) ,\\\\
  \\phi = Kangle \\cdot \\texttt{angle} (I) \\\\
\\end{array}\\f]

and
\\f[\\begin{array}{l}
  M = src.cols / log_e(maxRadius) \\\\
  Kangle = src.rows / 2\\Pi \\\\
\\end{array}\\f]

The function emulates the human "foveal" vision and can be used for fast scale and
rotation-invariant template matching, for object tracking and so forth.
@param src Source image
@param dst Destination image. It will have same size and type as src.
@param center The transformation center; where the output precision is maximal
@param M Magnitude scale parameter. It determines the radius of the bounding circle to transform too.
@param flags A combination of interpolation methods, see #InterpolationFlags

@note
-   The function can not operate in-place.
-   To calculate magnitude and angle in degrees #cartToPolar is used internally thus angles are measured from 0 to 360 with accuracy about 0.3 degrees.

@sa cv::linearPolar
@endinternal',0,'void',['Mat','src','',[]],['Mat','dst','',['/O']],['Point2f','center','',[]],['double','M','',[]],['int','flags','',[]]],
['','rectangle','@brief Draws a simple, thick, or filled up-right rectangle.

The function cv::rectangle draws a rectangle outline or a filled rectangle whose two opposite corners
are pt1 and pt2.

@param img Image.
@param pt1 Vertex of the rectangle.
@param pt2 Vertex of the rectangle opposite to pt1 .
@param color Rectangle color or brightness (grayscale image).
@param thickness Thickness of lines that make up the rectangle. Negative values, like #FILLED,
mean that the function has to draw a filled rectangle.
@param lineType Type of the line. See #LineTypes
@param shift Number of fractional bits in the point coordinates.',0,'void',['Mat','img','',['/IO']],['Point','pt1','',[]],['Point','pt2','',[]],['Scalar','color','',['/C','/Ref']],['int','thickness','1',[]],['int','lineType','LINE_8',[]],['int','shift','0',[]]],
);

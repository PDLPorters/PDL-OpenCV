(
['GeneralizedHough','detect','',1,'void',['Mat','image','',[]],['Mat','positions','',['/O']],['Mat','votes','Mat()',['/O']]],
['GeneralizedHough','detect','',1,'void',['Mat','edges','',[]],['Mat','dx','',[]],['Mat','dy','',[]],['Mat','positions','',['/O']],['Mat','votes','Mat()',['/O']]],
['Subdiv2D','initDelaunay','@brief Creates a new empty Delaunay subdivision

    @param rect Rectangle that includes all of the 2D points that are to be added to the subdivision.',1,'void',['Rect','rect','',[]]],
['Subdiv2D','insert','@brief Insert a single point into a Delaunay triangulation.

    @param pt Point to insert.

    The function inserts a single point into a subdivision and modifies the subdivision topology
    appropriately. If a point with the same coordinates exists already, no new point is added.
    @returns the ID of the point.

    @note If the point is outside of the triangulation specified rect a runtime error is raised.',1,'int',['Point2f','pt','',[]]],
['Subdiv2D','insert','@brief Insert multiple points into a Delaunay triangulation.

    @param ptvec Points to insert.

    The function inserts a vector of points into a subdivision and modifies the subdivision topology
    appropriately.',1,'void',['vector_Point2f','ptvec','',['/C','/Ref']]],
['Subdiv2D','getTriangleList','@brief Returns a list of all triangles.

    @param triangleList Output vector.

    The function gives each triangle as a 6 numbers vector, where each two are one of the triangle
    vertices. i.e. p1_x = v[0], p1_y = v[1], p2_x = v[2], p2_y = v[3], p3_x = v[4], p3_y = v[5].',1,'void',['vector_Vec6f','triangleList','',['/O','/Ref']]],
['Subdiv2D','getVoronoiFacetList','@brief Returns a list of all Voronoi facets.

    @param idx Vector of vertices IDs to consider. For all vertices you can pass empty vector.
    @param facetList Output vector of the Voronoi facets.
    @param facetCenters Output vector of the Voronoi facets center points.',1,'void',['vector_int','idx','',['/C','/Ref']],['vector_vector_Point2f','facetList','',['/O','/Ref']],['vector_Point2f','facetCenters','',['/O','/Ref']]],
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
['LineSegmentDetector','compareSegments','@brief Draws two groups of lines in blue and red, counting the non overlapping (mismatching) pixels.

    @param size The size of the image, where lines1 and lines2 were found.
    @param lines1 The first group of lines that needs to be drawn. It is visualized in blue color.
    @param lines2 The second group of lines. They visualized in red color.
    @param image Optional image, where the lines will be drawn. The image should be color(3-channel)
    in order for lines1 and lines2 to be drawn in the above mentioned colors.',1,'int',['Size','size','',['/C','/Ref']],['Mat','lines1','',[]],['Mat','lines2','',[]],['Mat','image','Mat()',['/IO']]],
['','getGaborKernel','@brief Returns Gabor filter coefficients.

For more details about gabor filter equations and parameters, see: [Gabor
Filter](http://en.wikipedia.org/wiki/Gabor_filter).

@param ksize Size of the filter returned.
@param sigma Standard deviation of the gaussian envelope.
@param theta Orientation of the normal to the parallel stripes of a Gabor function.
@param lambd Wavelength of the sinusoidal factor.
@param gamma Spatial aspect ratio.
@param psi Phase offset.
@param ktype Type of filter coefficients. It can be CV_32F or CV_64F .',0,'Mat',['Size','ksize','',[]],['double','sigma','',[]],['double','theta','',[]],['double','lambd','',[]],['double','gamma','',[]],['double','psi','CV_PI*0.5',[]],['int','ktype','CV_64F',[]]],
['','getAffineTransform','@overload',0,'Mat',['Mat','src','',[]],['Mat','dst','',[]]],
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
['','threshold','@brief Applies a fixed-level threshold to each array element.

The function applies fixed-level thresholding to a multiple-channel array. The function is typically
used to get a bi-level (binary) image out of a grayscale image ( #compare could be also used for
this purpose) or for removing a noise, that is, filtering out pixels with too small or too large
values. There are several types of thresholding supported by the function. They are determined by
type parameter.

Also, the special values #THRESH_OTSU or #THRESH_TRIANGLE may be combined with one of the
above values. In these cases, the function determines the optimal threshold value using the Otsu\'s
or Triangle algorithm and uses it instead of the specified thresh.

@note Currently, the Otsu\'s and Triangle methods are implemented only for 8-bit single-channel images.

@param src input array (multiple-channel, 8-bit or 32-bit floating point).
@param dst output array of the same size  and type and the same number of channels as src.
@param thresh threshold value.
@param maxval maximum value to use with the #THRESH_BINARY and #THRESH_BINARY_INV thresholding
types.
@param type thresholding type (see #ThresholdTypes).
@return the computed threshold value if Otsu\'s or Triangle methods used.

@sa  adaptiveThreshold, findContours, compare, min, max',0,'double',['Mat','src','',[]],['Mat','dst','',['/O']],['double','thresh','',[]],['double','maxval','',[]],['int','type','',[]]],
['','equalizeHist','@brief Equalizes the histogram of a grayscale image.

The function equalizes the histogram of the input image using the following algorithm:

- Calculate the histogram \\f$H\\f$ for src .
- Normalize the histogram so that the sum of histogram bins is 255.
- Compute the integral of the histogram:
\\f[H\'_i =  \\sum _{0  \\le j < i} H(j)\\f]
- Transform the image using \\f$H\'\\f$ as a look-up table: \\f$\\texttt{dst}(x,y) = H\'(\\texttt{src}(x,y))\\f$

The algorithm normalizes the brightness and increases the contrast of the image.

@param src Source 8-bit single channel image.
@param dst Destination image of the same size and type as src .',0,'void',['Mat','src','',[]],['Mat','dst','',['/O']]],
['',['wrapperEMD','EMD'],'@brief Computes the "minimal work" distance between two weighted point configurations.

The function computes the earth mover distance and/or a lower boundary of the distance between the
two weighted point configurations. One of the applications described in @cite RubnerSept98,
@cite Rubner2000 is multi-dimensional histogram comparison for image retrieval. EMD is a transportation
problem that is solved using some modification of a simplex algorithm, thus the complexity is
exponential in the worst case, though, on average it is much faster. In the case of a real metric
the lower boundary can be calculated even faster (using linear-time algorithm) and it can be used
to determine roughly whether the two signatures are far enough so that they cannot relate to the
same object.

@param signature1 First signature, a \\f$\\texttt{size1}\\times \\texttt{dims}+1\\f$ floating-point matrix.
Each row stores the point weight followed by the point coordinates. The matrix is allowed to have
a single column (weights only) if the user-defined cost matrix is used. The weights must be
non-negative and have at least one non-zero value.
@param signature2 Second signature of the same format as signature1 , though the number of rows
may be different. The total weights may be different. In this case an extra "dummy" point is added
to either signature1 or signature2. The weights must be non-negative and have at least one non-zero
value.
@param distType Used metric. See #DistanceTypes.
@param cost User-defined \\f$\\texttt{size1}\\times \\texttt{size2}\\f$ cost matrix. Also, if a cost matrix
is used, lower boundary lowerBound cannot be calculated because it needs a metric function.
@param lowerBound Optional input/output parameter: lower boundary of a distance between the two
signatures that is a distance between mass centers. The lower boundary may not be calculated if
the user-defined cost matrix is used, the total weights of point configurations are not equal, or
if the signatures consist of weights only (the signature matrices have a single column). You
**must** initialize \\*lowerBound . If the calculated distance between mass centers is greater or
equal to \\*lowerBound (it means that the signatures are far enough), the function does not
calculate EMD. In any case \\*lowerBound is set to the calculated distance between mass centers on
return. Thus, if you want to calculate both distance between mass centers and EMD, \\*lowerBound
should be set to 0.
@param flow Resultant \\f$\\texttt{size1} \\times \\texttt{size2}\\f$ flow matrix: \\f$\\texttt{flow}_{i,j}\\f$ is
a flow from \\f$i\\f$ -th point of signature1 to \\f$j\\f$ -th point of signature2 .',0,'float',['Mat','signature1','',[]],['Mat','signature2','',[]],['int','distType','',[]],['Mat','cost','Mat()',[]],['Ptr_float','lowerBound','Ptr<float>()',['/IO']],['Mat','flow','Mat()',['/O']]],
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
['','cvtColorTwoPlane','@brief Converts an image from one color space to another where the source image is
stored in two planes.

This function only supports YUV420 to RGB conversion as of now.

@param src1: 8-bit image (#CV_8U) of the Y plane.
@param src2: image containing interleaved U/V plane.
@param dst: output image.
@param code: Specifies the type of conversion. It can take any of the following values:
- #COLOR_YUV2BGR_NV12
- #COLOR_YUV2RGB_NV12
- #COLOR_YUV2BGRA_NV12
- #COLOR_YUV2RGBA_NV12
- #COLOR_YUV2BGR_NV21
- #COLOR_YUV2RGB_NV21
- #COLOR_YUV2BGRA_NV21
- #COLOR_YUV2RGBA_NV21',0,'void',['Mat','src1','',[]],['Mat','src2','',[]],['Mat','dst','',['/O']],['int','code','',[]]],
['','findContours','@brief Finds contours in a binary image.

The function retrieves contours from the binary image using the algorithm @cite Suzuki85 . The contours
are a useful tool for shape analysis and object detection and recognition. See squares.cpp in the
OpenCV sample directory.
@note Since opencv 3.2 source image is not modified by this function.

@param image Source, an 8-bit single-channel image. Non-zero pixels are treated as 1\'s. Zero
pixels remain 0\'s, so the image is treated as binary . You can use #compare, #inRange, #threshold ,
#adaptiveThreshold, #Canny, and others to create a binary image out of a grayscale or color one.
If mode equals to #RETR_CCOMP or #RETR_FLOODFILL, the input can also be a 32-bit integer image of labels (CV_32SC1).
@param contours Detected contours. Each contour is stored as a vector of points (e.g.
std::vector<std::vector<cv::Point> >).
@param hierarchy Optional output vector (e.g. std::vector<cv::Vec4i>), containing information about the image topology. It has
as many elements as the number of contours. For each i-th contour contours[i], the elements
hierarchy[i][0] , hierarchy[i][1] , hierarchy[i][2] , and hierarchy[i][3] are set to 0-based indices
in contours of the next and previous contours at the same hierarchical level, the first child
contour and the parent contour, respectively. If for the contour i there are no next, previous,
parent, or nested contours, the corresponding elements of hierarchy[i] will be negative.
@note In Python, hierarchy is nested inside a top level array. Use hierarchy[0][i] to access hierarchical elements of i-th contour.
@param mode Contour retrieval mode, see #RetrievalModes
@param method Contour approximation method, see #ContourApproximationModes
@param offset Optional offset by which every contour point is shifted. This is useful if the
contours are extracted from the image ROI and then they should be analyzed in the whole image
context.',0,'void',['Mat','image','',[]],['vector_Mat','contours','',['/O']],['Mat','hierarchy','',['/O']],['int','mode','',[]],['int','method','',[]],['Point','offset','Point()',[]]],
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
['','rectangle','@overload

use `rec` parameter as alternative specification of the drawn rectangle: `r.tl() and
r.br()-Point(1,1)` are opposite corners',0,'void',['Mat','img','',['/IO']],['Rect','rec','',[]],['Scalar','color','',['/C','/Ref']],['int','thickness','1',[]],['int','lineType','LINE_8',[]],['int','shift','0',[]]],
['','drawContours','@brief Draws contours outlines or filled contours.

The function draws contour outlines in the image if \\f$\\texttt{thickness} \\ge 0\\f$ or fills the area
bounded by the contours if \\f$\\texttt{thickness}<0\\f$ . The example below shows how to retrieve
connected components from the binary image and label them: :
@include snippets/imgproc_drawContours.cpp

@param image Destination image.
@param contours All the input contours. Each contour is stored as a point vector.
@param contourIdx Parameter indicating a contour to draw. If it is negative, all the contours are drawn.
@param color Color of the contours.
@param thickness Thickness of lines the contours are drawn with. If it is negative (for example,
thickness=#FILLED ), the contour interiors are drawn.
@param lineType Line connectivity. See #LineTypes
@param hierarchy Optional information about hierarchy. It is only needed if you want to draw only
some of the contours (see maxLevel ).
@param maxLevel Maximal level for drawn contours. If it is 0, only the specified contour is drawn.
If it is 1, the function draws the contour(s) and all the nested contours. If it is 2, the function
draws the contours, all the nested contours, all the nested-to-nested contours, and so on. This
parameter is only taken into account when there is hierarchy available.
@param offset Optional contour shift parameter. Shift all the drawn contours by the specified
\\f$\\texttt{offset}=(dx,dy)\\f$ .
@note When thickness=#FILLED, the function is designed to handle connected components with holes correctly
even when no hierarchy data is provided. This is done by analyzing all the outlines together
using even-odd rule. This may give incorrect results if you have a joint collection of separately retrieved
contours. In order to solve this problem, you need to call #drawContours separately for each sub-group
of contours, or iterate over the collection using contourIdx parameter.',0,'void',['Mat','image','',['/IO']],['vector_Mat','contours','',[]],['int','contourIdx','',[]],['Scalar','color','',['/C','/Ref']],['int','thickness','1',[]],['int','lineType','LINE_8',[]],['Mat','hierarchy','Mat()',[]],['int','maxLevel','INT_MAX',[]],['Point','offset','Point()',[]]],
['','ellipse2Poly','@brief Approximates an elliptic arc with a polyline.

The function ellipse2Poly computes the vertices of a polyline that approximates the specified
elliptic arc. It is used by #ellipse. If `arcStart` is greater than `arcEnd`, they are swapped.

@param center Center of the arc.
@param axes Half of the size of the ellipse main axes. See #ellipse for details.
@param angle Rotation angle of the ellipse in degrees. See #ellipse for details.
@param arcStart Starting angle of the elliptic arc in degrees.
@param arcEnd Ending angle of the elliptic arc in degrees.
@param delta Angle between the subsequent polyline vertices. It defines the approximation
accuracy.
@param pts Output vector of polyline vertices.',0,'void',['Point','center','',[]],['Size','axes','',[]],['int','angle','',[]],['int','arcStart','',[]],['int','arcEnd','',[]],['int','delta','',[]],['vector_Point','pts','',['/O','/Ref']]],
);

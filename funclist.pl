(
['Algorithm','read','@brief Reads algorithm parameters from a file storage',1,'void',['FileNode','fn','',['/C','/Ref']]],
['Algorithm','write','@brief simplified API for language bindings
    * @overload',1,'void',['Ptr_FileStorage','fs','',['/C','/Ref']],['String','name','String()',['/C','/Ref']]],
['FileNode','keys','@brief Returns keys of a mapping node.
     @returns Keys of a mapping node.',1,'vector_String'],
['FileStorage','getFirstTopLevelNode','@brief Returns the first element of the top-level mapping.
     @returns The first element of the top-level mapping.',1,'FileNode'],
['FileStorage',['operator[]','getNode'],'@overload',1,'FileNode',['c_string','nodename','',['/C']]],
['KeyPoint','convert','@overload
    @param points2f Array of (x,y) coordinates of each keypoint
    @param keypoints Keypoints obtained from any feature detection algorithm like SIFT/SURF/ORB
    @param size keypoint diameter
    @param response keypoint detector response on the keypoint (that is, strength of the keypoint)
    @param octave pyramid octave in which the keypoint has been detected
    @param class_id object id',0,'void',['vector_Point2f','points2f','',['/C','/Ref']],['vector_KeyPoint','keypoints','',['/O','/Ref']],['float','size','1',[]],['float','response','1',[]],['int','octave','0',[]],['int','class_id','-1',[]]],
['KeyPoint','overlap','This method computes overlap for pair of keypoints. Overlap is the ratio between area of keypoint
    regions\' intersection and area of keypoint regions\' union (considering keypoint region as circle).
    If they don\'t overlap, we get zero. If they coincide at same location with same size, we get 1.
    @param kp1 First keypoint
    @param kp2 Second keypoint',0,'float',['KeyPoint','kp1','',['/C','/Ref']],['KeyPoint','kp2','',['/C','/Ref']]],
['','batchDistance','@brief naive nearest neighbor finder

see http://en.wikipedia.org/wiki/Nearest_neighbor_search
@todo document',0,'void',['Mat','src1','',[]],['Mat','src2','',[]],['Mat','dist','',['/O']],['int','dtype','',[]],['Mat','nidx','',['/O']],['int','normType','NORM_L2',[]],['int','K','0',[]],['Mat','mask','Mat()',[]],['int','update','0',[]],['bool','crosscheck','false',[]]],
['','hconcat','@overload
 @code{.cpp}
    std::vector<cv::Mat> matrices = { cv::Mat(4, 1, CV_8UC1, cv::Scalar(1)),
                                      cv::Mat(4, 1, CV_8UC1, cv::Scalar(2)),
                                      cv::Mat(4, 1, CV_8UC1, cv::Scalar(3)),};

    cv::Mat out;
    cv::hconcat( matrices, out );
    //out:
    //[1, 2, 3;
    // 1, 2, 3;
    // 1, 2, 3;
    // 1, 2, 3]
 @endcode
 @param src input array or vector of matrices. all of the matrices must have the same number of rows and the same depth.
 @param dst output array. It has the same number of rows and depth as the src, and the sum of cols of the src.
same depth.',0,'void',['vector_Mat','src','',[]],['Mat','dst','',['/O']]],
['','minMaxLoc','@brief Finds the global minimum and maximum in an array.

The function cv::minMaxLoc finds the minimum and maximum element values and their positions. The
extremums are searched across the whole array or, if mask is not an empty array, in the specified
array region.

The function do not work with multi-channel arrays. If you need to find minimum or maximum
elements across all the channels, use Mat::reshape first to reinterpret the array as
single-channel. Or you may extract the particular channel using either extractImageCOI , or
mixChannels , or split .
@param src input single-channel array.
@param minVal pointer to the returned minimum value; NULL is used if not required.
@param maxVal pointer to the returned maximum value; NULL is used if not required.
@param minLoc pointer to the returned minimum location (in 2D case); NULL is used if not required.
@param maxLoc pointer to the returned maximum location (in 2D case); NULL is used if not required.
@param mask optional mask used to select a sub-array.
@sa max, min, compare, inRange, extractImageCOI, mixChannels, split, Mat::reshape',0,'void',['Mat','src','',[]],['double*','minVal','',['/O']],['double*','maxVal','0',['/O']],['Point*','minLoc','0',['/O']],['Point*','maxLoc','0',['/O']],['Mat','mask','Mat()',[]]],
['','mixChannels','@overload
@param src input array or vector of matrices; all of the matrices must have the same size and the
same depth.
@param dst output array or vector of matrices; all the matrices **must be allocated**; their size and
depth must be the same as in src[0].
@param fromTo array of index pairs specifying which channels are copied and where; fromTo[k\\*2] is
a 0-based index of the input channel in src, fromTo[k\\*2+1] is an index of the output channel in
dst; the continuous channel numbering is used: the first input image channels are indexed from 0 to
src[0].channels()-1, the second input image channels are indexed from src[0].channels() to
src[0].channels() + src[1].channels()-1, and so on, the same scheme is used for the output image
channels; as a special case, when fromTo[k\\*2] is negative, the corresponding output channel is
filled with zero .',0,'void',['vector_Mat','src','',[]],['vector_Mat','dst','',['/IO']],['vector_int','fromTo','',['/C','/Ref']]],
['','normalize','@brief Normalizes the norm or value range of an array.

The function cv::normalize normalizes scale and shift the input array elements so that
\\f[\\| \\texttt{dst} \\| _{L_p}= \\texttt{alpha}\\f]
(where p=Inf, 1 or 2) when normType=NORM_INF, NORM_L1, or NORM_L2, respectively; or so that
\\f[\\min _I  \\texttt{dst} (I)= \\texttt{alpha} , \\, \\, \\max _I  \\texttt{dst} (I)= \\texttt{beta}\\f]

when normType=NORM_MINMAX (for dense arrays only). The optional mask specifies a sub-array to be
normalized. This means that the norm or min-n-max are calculated over the sub-array, and then this
sub-array is modified to be normalized. If you want to only use the mask to calculate the norm or
min-max but modify the whole array, you can use norm and Mat::convertTo.

In case of sparse matrices, only the non-zero values are analyzed and transformed. Because of this,
the range transformation for sparse matrices is not allowed since it can shift the zero level.

Possible usage with some positive example data:
@code{.cpp}
    vector<double> positiveData = { 2.0, 8.0, 10.0 };
    vector<double> normalizedData_l1, normalizedData_l2, normalizedData_inf, normalizedData_minmax;

    // Norm to probability (total count)
    // sum(numbers) = 20.0
    // 2.0      0.1     (2.0/20.0)
    // 8.0      0.4     (8.0/20.0)
    // 10.0     0.5     (10.0/20.0)
    normalize(positiveData, normalizedData_l1, 1.0, 0.0, NORM_L1);

    // Norm to unit vector: ||positiveData|| = 1.0
    // 2.0      0.15
    // 8.0      0.62
    // 10.0     0.77
    normalize(positiveData, normalizedData_l2, 1.0, 0.0, NORM_L2);

    // Norm to max element
    // 2.0      0.2     (2.0/10.0)
    // 8.0      0.8     (8.0/10.0)
    // 10.0     1.0     (10.0/10.0)
    normalize(positiveData, normalizedData_inf, 1.0, 0.0, NORM_INF);

    // Norm to range [0.0;1.0]
    // 2.0      0.0     (shift to left border)
    // 8.0      0.75    (6.0/8.0)
    // 10.0     1.0     (shift to right border)
    normalize(positiveData, normalizedData_minmax, 1.0, 0.0, NORM_MINMAX);
@endcode

@param src input array.
@param dst output array of the same size as src .
@param alpha norm value to normalize to or the lower range boundary in case of the range
normalization.
@param beta upper range boundary in case of the range normalization; it is not used for the norm
normalization.
@param norm_type normalization type (see cv::NormTypes).
@param dtype when negative, the output array has the same type as src; otherwise, it has the same
number of channels as src and the depth =CV_MAT_DEPTH(dtype).
@param mask optional operation mask.
@sa norm, Mat::convertTo, SparseMat::convertTo',0,'void',['Mat','src','',[]],['Mat','dst','',['/IO']],['double','alpha','1',[]],['double','beta','0',[]],['int','norm_type','NORM_L2',[]],['int','dtype','-1',[]],['Mat','mask','Mat()',[]]],
['',['sum','sumElems'],'@brief Calculates the sum of array elements.

The function cv::sum calculates and returns the sum of array elements,
independently for each channel.
@param src input array that must have from 1 to 4 channels.
@sa  countNonZero, mean, meanStdDev, norm, minMaxLoc, reduce',0,'Scalar',['Mat','src','',[]]],
);

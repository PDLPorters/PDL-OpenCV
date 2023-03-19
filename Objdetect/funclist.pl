(
['CascadeClassifier','detectMultiScale','@brief Detects objects of different sizes in the input image. The detected objects are returned as a list
    of rectangles.

    @param image Matrix of the type CV_8U containing an image where objects are detected.
    @param objects Vector of rectangles where each rectangle contains the detected object, the
    rectangles may be partially outside the original image.
    @param scaleFactor Parameter specifying how much the image size is reduced at each image scale.
    @param minNeighbors Parameter specifying how many neighbors each candidate rectangle should have
    to retain it.
    @param flags Parameter with the same meaning for an old cascade as in the function
    cvHaarDetectObjects. It is not used for a new cascade.
    @param minSize Minimum possible object size. Objects smaller than that are ignored.
    @param maxSize Maximum possible object size. Objects larger than that are ignored. If `maxSize == minSize` model is evaluated on single scale.

    The function is parallelized with the TBB library.

    @note
       -   (Python) A face detection example using cascade classifiers can be found at
            opencv_source_code/samples/python/facedetect.py',1,'void',['Mat','image','',[]],['vector_Rect','objects','',['/O','/Ref']],['double','scaleFactor','1.1',[]],['int','minNeighbors','3',[]],['int','flags','0',[]],['Size','minSize','Size()',[]],['Size','maxSize','Size()',[]]],
['CascadeClassifier',['detectMultiScale','detectMultiScale2'],'@overload
    @param image Matrix of the type CV_8U containing an image where objects are detected.
    @param objects Vector of rectangles where each rectangle contains the detected object, the
    rectangles may be partially outside the original image.
    @param numDetections Vector of detection numbers for the corresponding objects. An object\'s number
    of detections is the number of neighboring positively classified rectangles that were joined
    together to form the object.
    @param scaleFactor Parameter specifying how much the image size is reduced at each image scale.
    @param minNeighbors Parameter specifying how many neighbors each candidate rectangle should have
    to retain it.
    @param flags Parameter with the same meaning for an old cascade as in the function
    cvHaarDetectObjects. It is not used for a new cascade.
    @param minSize Minimum possible object size. Objects smaller than that are ignored.
    @param maxSize Maximum possible object size. Objects larger than that are ignored. If `maxSize == minSize` model is evaluated on single scale.',1,'void',['Mat','image','',[]],['vector_Rect','objects','',['/O','/Ref']],['vector_int','numDetections','',['/O','/Ref']],['double','scaleFactor','1.1',[]],['int','minNeighbors','3',[]],['int','flags','0',[]],['Size','minSize','Size()',[]],['Size','maxSize','Size()',[]]],
['CascadeClassifier',['detectMultiScale','detectMultiScale3'],'@overload
    This function allows you to retrieve the final stage decision certainty of classification.
    For this, one needs to set `outputRejectLevels` on true and provide the `rejectLevels` and `levelWeights` parameter.
    For each resulting detection, `levelWeights` will then contain the certainty of classification at the final stage.
    This value can then be used to separate strong from weaker classifications.

    A code sample on how to use it efficiently can be found below:
    @code
    Mat img;
    vector<double> weights;
    vector<int> levels;
    vector<Rect> detections;
    CascadeClassifier model("/path/to/your/model.xml");
    model.detectMultiScale(img, detections, levels, weights, 1.1, 3, 0, Size(), Size(), true);
    cerr << "Detection " << detections[0] << " with weight " << weights[0] << endl;
    @endcode',1,'void',['Mat','image','',[]],['vector_Rect','objects','',['/O','/Ref']],['vector_int','rejectLevels','',['/O','/Ref']],['vector_double','levelWeights','',['/O','/Ref']],['double','scaleFactor','1.1',[]],['int','minNeighbors','3',[]],['int','flags','0',[]],['Size','minSize','Size()',[]],['Size','maxSize','Size()',[]],['bool','outputRejectLevels','false',[]]],
['CascadeClassifier','load','@brief Loads a classifier from a file.

    @param filename Name of the file from which the classifier is loaded. The file may contain an old
    HAAR classifier trained by the haartraining application or a new cascade classifier trained by the
    traincascade application.',1,'bool',['String','filename','',['/C','/Ref']]],
['CascadeClassifier','read','@brief Reads a classifier from a FileStorage node.

    @note The file may contain a new cascade classifier (trained traincascade application) only.',1,'bool',['FileNode','node','',['/C','/Ref']]],
['HOGDescriptor','compute','@brief Computes HOG descriptors of given image.
    @param img Matrix of the type CV_8U containing an image where HOG features will be calculated.
    @param descriptors Matrix of the type CV_32F
    @param winStride Window stride. It must be a multiple of block stride.
    @param padding Padding
    @param locations Vector of Point',1,'void',['Mat','img','',[]],['vector_float','descriptors','',['/O','/Ref']],['Size','winStride','Size()',[]],['Size','padding','Size()',[]],['vector_Point','locations','std::vector<Point>()',['/C','/Ref']]],
['HOGDescriptor','detectMultiScale','@brief Detects objects of different sizes in the input image. The detected objects are returned as a list
    of rectangles.
    @param img Matrix of the type CV_8U or CV_8UC3 containing an image where objects are detected.
    @param foundLocations Vector of rectangles where each rectangle contains the detected object.
    @param foundWeights Vector that will contain confidence values for each detected object.
    @param hitThreshold Threshold for the distance between features and SVM classifying plane.
    Usually it is 0 and should be specified in the detector coefficients (as the last free coefficient).
    But if the free coefficient is omitted (which is allowed), you can specify it manually here.
    @param winStride Window stride. It must be a multiple of block stride.
    @param padding Padding
    @param scale Coefficient of the detection window increase.
    @param finalThreshold Final threshold
    @param useMeanshiftGrouping indicates grouping algorithm',1,'void',['Mat','img','',[]],['vector_Rect','foundLocations','',['/O','/Ref']],['vector_double','foundWeights','',['/O','/Ref']],['double','hitThreshold','0',[]],['Size','winStride','Size()',[]],['Size','padding','Size()',[]],['double','scale','1.05',[]],['double','finalThreshold','2.0',[]],['bool','useMeanshiftGrouping','false',[]]],
['QRCodeDetector','detectAndDecodeMulti','@brief Both detects and decodes QR codes
    @param img grayscale or color (BGR) image containing QR codes.
    @param decoded_info UTF8-encoded output vector of string or empty vector of string if the codes cannot be decoded.
    @param points optional output vector of vertices of the found QR code quadrangles. Will be empty if not found.
    @param straight_qrcode The optional output vector of images containing rectified and binarized QR codes',1,'bool',['Mat','img','',[]],['vector_string','decoded_info','',['/O','/Ref']],['Mat','points','Mat()',['/O']],['vector_Mat','straight_qrcode','vector_Mat()',['/O']]],
['','groupRectangles','@overload',0,'void',['vector_Rect','rectList','',['/IO','/Ref']],['vector_int','weights','',['/O','/Ref']],['int','groupThreshold','',[]],['double','eps','0.2',[]]],
);

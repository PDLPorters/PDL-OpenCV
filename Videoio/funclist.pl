(
['VideoCapture','get','@brief Returns the specified VideoCapture property

    @param propId Property identifier from cv::VideoCaptureProperties (eg. cv::CAP_PROP_POS_MSEC, cv::CAP_PROP_POS_FRAMES, ...)
    or one from @ref videoio_flags_others
    @return Value for the specified property. Value 0 is returned when querying a property that is
    not supported by the backend used by the VideoCapture instance.

    @note Reading / writing properties involves many layers. Some unexpected result might happens
    along this chain.
    @code{.txt}
    VideoCapture -> API Backend -> Operating System -> Device Driver -> Device Hardware
    @endcode
    The returned value might be different from what really used by the device or it could be encoded
    using device dependent rules (eg. steps or percentage). Effective behaviour depends from device
    driver and API Backend',1,'double',['int','propId','',[]]],
['VideoCapture','getBackendName','@brief Returns used backend API name

     @note Stream should be opened.',1,'String'],
['VideoCapture','open','@brief  Opens a camera for video capturing

    @overload

    The `params` parameter allows to specify extra parameters encoded as pairs `(paramId_1, paramValue_1, paramId_2, paramValue_2, ...)`.
    See cv::VideoCaptureProperties

    @return `true` if the file has been successfully opened

    The method first calls VideoCapture::release to close the already opened file or camera.',1,'bool',['String','filename','',['/C','/Ref']],['int','apiPreference','',[]],['vector_int','params','',['/C','/Ref']]],
['VideoCapture','read','@brief Grabs, decodes and returns the next video frame.

    @param [out] image the video frame is returned here. If no frames has been grabbed the image will be empty.
    @return `false` if no frames has been grabbed

    The method/function combines VideoCapture::grab() and VideoCapture::retrieve() in one call. This is the
    most convenient method for reading video files or capturing data from decode and returns the just
    grabbed frame. If no frames has been grabbed (camera has been disconnected, or there are no more
    frames in video file), the method returns false and the function returns empty image (with %cv::Mat, test it with Mat::empty()).

    @note In @ref videoio_c "C API", functions cvRetrieveFrame() and cv.RetrieveFrame() return image stored inside the video
    capturing structure. It is not allowed to modify or release the image! You can copy the frame using
    cvCloneImage and then do whatever you want with the copy.',1,'bool',['Mat','image','',['/O']]],
['VideoWriter','fourcc','@brief Concatenates 4 chars to a fourcc code

    @return a fourcc code

    This static method constructs the fourcc code of the codec to be used in the constructor
    VideoWriter::VideoWriter or VideoWriter::open.',0,'int',['char','c1','',[]],['char','c2','',[]],['char','c3','',[]],['char','c4','',[]]],
['VideoWriter','open','@brief Initializes or reinitializes video writer.

    The method opens video writer. Parameters are the same as in the constructor
    VideoWriter::VideoWriter.
    @return `true` if video writer has been successfully initialized

    The method first calls VideoWriter::release to close the already opened file.',1,'bool',['String','filename','',['/C','/Ref']],['int','fourcc','',[]],['double','fps','',[]],['Size','frameSize','',[]],['bool','isColor','true',[]]],
['VideoWriter','write','@brief Writes the next video frame

    @param image The written frame. In general, color images are expected in BGR format.

    The function/method writes the specified image to video file. It must have the same size as has
    been specified when opening the video writer.',1,'void',['Mat','image','',[]]],
);

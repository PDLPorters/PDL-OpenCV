(
['SparseOpticalFlow','calc','@brief Calculates a sparse optical flow.

    @param prevImg First input image.
    @param nextImg Second input image of the same size and the same type as prevImg.
    @param prevPts Vector of 2D points for which the flow needs to be found.
    @param nextPts Output vector of 2D points containing the calculated new positions of input features in the second image.
    @param status Output status vector. Each element of the vector is set to 1 if the
                  flow for the corresponding features has been found. Otherwise, it is set to 0.
    @param err Optional output vector that contains error response for each point (inverse confidence).',1,'void',['Mat','prevImg','',[]],['Mat','nextImg','',[]],['Mat','prevPts','',[]],['Mat','nextPts','',['/IO']],['Mat','status','',['/O']],['Mat','err','cv::Mat()',['/O']]],
['Tracker','init','@brief Initialize the tracker with a known bounding box that surrounded the target
    @param image The initial frame
    @param boundingBox The initial bounding box',1,'void',['Mat','image','',[]],['Rect','boundingBox','',['/C','/Ref']]],
['Tracker','update','@brief Update the tracker, find the new most likely bounding box for the target
    @param image The current frame
    @param boundingBox The bounding box that represent the new target location, if true was returned, not
    modified otherwise

    @return True means that target was located and false means that tracker cannot locate target in
    current frame. Note, that latter *does not* imply that tracker has failed, maybe target is indeed
    missing from the frame (say, out of sight)',1,'bool',['Mat','image','',[]],['Rect','boundingBox','',['/O','/Ref']]],
);

(
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

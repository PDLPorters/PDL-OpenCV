(
['QRCodeDetector','detectAndDecodeMulti','@brief Both detects and decodes QR codes
    @param img grayscale or color (BGR) image containing QR codes.
    @param decoded_info UTF8-encoded output vector of string or empty vector of string if the codes cannot be decoded.
    @param points optional output vector of vertices of the found QR code quadrangles. Will be empty if not found.
    @param straight_qrcode The optional output vector of images containing rectified and binarized QR codes',1,'bool',['Mat','img','',[]],['vector_string','decoded_info','',['/O','/Ref']],['Mat','points','Mat()',['/O']],['vector_Mat','straight_qrcode','vector_Mat()',['/O']]],
);

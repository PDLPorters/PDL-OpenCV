(
  ['VideoCapture','read',"Read a frame from the source, return also whether succeeded",1,'bool',["Mat","image","",["/O"]]],
  ['VideoCapture','open',"Initialize OpenCV videocapture.\n\n=for example\n\n  \$succeeded = \$vc->open(\$uri);\n",1,'bool',['String','filename'],['int','apiPreference','CAP_ANY',[]]],
  ['VideoCapture','get',"Return a VideoCapture object's property",1,'double',['int','propId']],
  ['VideoWriter','open',"Open writing to given filename",1,'int',['String','name'],['int','fourcc'],['double','fps'],['Size','size'],['int','iscolor']],
  ['VideoWriter','write',"Write a frame to the file.",1,'void',["Mat","image"]],
  ['VideoWriter','fourcc',"Turn 4 chars into fourcc int",0,'int',['char','c1'],['char','c2'],['char','c3'],['char','c4']],
);

# define generated functions.
# [ name, ismethod(2=attribute), returntype, \%options, @arguments ]
(
['','normalize',0,'void',{},['MatWrapper *','mw'],['MatWrapper *','out'],['int','start'],['int','end'],['int','type']],
['','minMaxIdx',0,'void',{},['MatWrapper *','mw'],["double *","mymin"],["double *","mymax"]],
['','imshow',0,'void',{},['const char *','name'],['MatWrapper *','mw']],
['','cvtColor',0,'void',{},['MatWrapper *','mw'],['MatWrapper *','out'],['int','rtype']],
['VideoWriter','fourcc',0,'int',{},['char','c1'],['char','c2'],['char','c3'],['char','c4']],
['VideoWriter','open',1,'char',{},['VideoWriterWrapper *','vw'],['const char *','name'],['int','fourcc'],['double','fps'],['SizeWrapper*','size'],['char','iscolor']],
['VideoWriter','write',1,'void',{},['VideoWriterWrapper *','vw'],['MatWrapper*','mw']],
['VideoCapture','open',1,'char',{},['VideoCaptureWrapper *','vw'],['const char *','name']],
['VideoCapture','read',1,'char',{},['VideoCaptureWrapper *','vw'],['MatWrapper*','mw']],
['Mat','channels',1,'int',{},['MatWrapper *','mw']],
['Mat','ptr',1,'void *',{},['MatWrapper *','mw']],
['Mat','rows',2,'int',{},['MatWrapper *','mw']],
['Mat','cols',2,'int',{},['MatWrapper *','mw']],
['Mat','convertTo',1,'void',{},['MatWrapper *','mw'],['MatWrapper *','out'],['int','rtype'],['double','alpha'],['double','beta']],
);

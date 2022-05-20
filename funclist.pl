# define generated functions.
# [ name, ismethod(2=attribute), returntype, \%options, @arguments ]
(
['','normalize',0,'void',{},['MatWrapper *','mw'],['MatWrapper *','out'],['int','start'],['int','end'],['int','type']],
['','minMaxIdx',0,'void',{},['MatWrapper *','mw'],["double *","mymin"],["double *","mymax"]],
['','imshow',0,'void',{},['const char *','name'],['MatWrapper *','mw']],
['','cvtColor',0,'void',{},["MatWrapper *","src","",[]],["MatWrapper *","dst","",["/O"]],["int","code","",[]],["int","dstCn","0",[]]],
['VideoWriter','fourcc',0,'int',{},['char','c1'],['char','c2'],['char','c3'],['char','c4']],
['VideoWriter','open',1,'char',{},['const char *','name'],['int','fourcc'],['double','fps'],['SizeWrapper*','size'],['char','iscolor']],
['VideoWriter','write',1,'void',{},['MatWrapper*','mw']],
['VideoCapture','open',1,'char',{},['const char *','name']],
['VideoCapture','read',1,'char',{},['MatWrapper*','mw']],
['VideoCapture','get',1,'double',{},['int','propId']],
['Mat','channels',1,'int',{}],
['Mat','ptr',1,'void *',{}],
['Mat','rows',2,'int',{}],
['Mat','cols',2,'int',{}],
['Mat','convertTo',1,'void',{},['MatWrapper *','out'],['int','rtype'],['double','alpha'],['double','beta']],
);

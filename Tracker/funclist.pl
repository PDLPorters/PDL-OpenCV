(
  ['Tracker','init',"Initialize OpenCV tracker",1,'void',{},['Mat','mw'],['Rect','roi']],
  ['Tracker','update',"Update tracker with new image",1,'int',{pre=>'TRACKER_RECT_TYPE box;',post=>'roi->held = box;',argfix=>sub{$_[0][1]='box'}},['Mat','mw'],['Rect','roi',"",['/O']]],
);

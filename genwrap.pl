use strict;
use warnings;
use FindBin qw($Bin);
use File::Spec::Functions;
use PDL::Types;
use PDL::Core qw/howbig/;

require ''. catfile $Bin, 'genpp.pl';
our (%type_overrides, %extra_cons_args);
my %GLOBALTYPES = do { no warnings 'once'; (%PP::OpenCV::DIMTYPES, Mat=>[]) };
my @PDLTYPES_SUPPORTED = grep $_->real && $_->ppsym !~/[KPQN]/ && howbig($_) <= 8, PDL::Types::types;
my %overrides = (
  Tracker => {
    update => {pre=>'TRACKER_RECT_TYPE box;',post=>'boundingBox->held = box;',argfix=>sub{$_[0][1]='box'}},
  },
);
my %ptr_only = map +($_=>1), qw(Tracker LineSegmentDetector);
my $CATCH = q[catch (const std::exception& e) {
  CW_err = {CW_EUSERERROR,strdup(e.what()),1};
 }];
my %constructor_override = (
  Tracker => <<EOF,
#if CV_VERSION_MINOR >= 5 && CV_VERSION_MAJOR >= 4
# define TRACKER_RECT_TYPE cv::Rect
#else
# define TRACKER_RECT_TYPE cv::Rect2d
#endif
cw_error cw_Tracker_new(TrackerWrapper **cw_retval, char *klass) {
 cw_error CW_err = {CW_ENONE, NULL, 0};
 try {
  *cw_retval = new TrackerWrapper;
  (*cw_retval)->held = cv::TrackerKCF::create();
 } $CATCH
 return CW_err;
}
EOF
  LineSegmentDetector => <<EOF,
cw_error cw_LineSegmentDetector_new(LineSegmentDetectorWrapper **cw_retval, char *klass, int lsd_type) {
 cw_error CW_err = {CW_ENONE, NULL, 0};
 try {
  *cw_retval = new LineSegmentDetectorWrapper;
  (*cw_retval)->held = cv::createLineSegmentDetector(lsd_type);
 } $CATCH
 return CW_err;
}
EOF
);
my @funclist = do ''. catfile curdir, 'funclist.pl'; die if $@;
my $CHEADER = <<'EOF';
#include <opencv2/opencv.hpp>
#include <opencv2/core/utility.hpp> /* allows control number of threads */
#include "opencv_wrapper.h"
#include "wraplocal.h"
/* use C name mangling */
extern "C" {
EOF
my $CBODY_GLOBAL = <<EOF;
cw_error cw_Mat_newWithDims(MatWrapper **cw_retval, const ptrdiff_t planes, const ptrdiff_t cols, const ptrdiff_t rows, const int type, void * data) {
 cw_error CW_err = {CW_ENONE, NULL, 0};
 try {
  *cw_retval = new MatWrapper;
  if (planes == 0 && cols == 0 && rows == 0) /* no check type as upgrade */
    (*cw_retval)->held = cv::Mat();
  else
    (*cw_retval)->held = cv::Mat(rows, cols, get_ocvtype(type,planes), data);
 } $CATCH
 return CW_err;
}
cw_error cw_Mat_pdlDims(MatWrapper *wrapper, int *t, ptrdiff_t *l, ptrdiff_t *c, ptrdiff_t *r) {
 cw_error CW_err = {CW_ENONE, NULL, 0};
 try {
  *t = get_pdltype(wrapper->held.type());
  *l = wrapper->held.channels();
  *c = wrapper->held.cols;
  *r = wrapper->held.rows;
 } $CATCH
 return CW_err;
}
cw_error cw_Mat_ptr(void **cw_retval, MatWrapper *self) {
 cw_error CW_err = {CW_ENONE, NULL, 0};
 try {
  *cw_retval = self->held.ptr();
 } $CATCH
 return CW_err;
}
EOF
my $CFOOTER = "}\n";
my $HHEADER = <<'EOF';
#ifndef %1$s_H
#define %1$s_H
#ifdef __cplusplus
extern "C" {
#endif
#include <stddef.h>
#ifndef _CW_ERROR_ALREADY
#define _CW_ERROR_ALREADY
/* can't directly include pdl.h so copy-paste and modify names: */
typedef enum {
  CW_ENONE = 0, /* usable as boolean */
  CW_EUSERERROR, /* user error, no need to destroy */
  CW_EFATAL
} cw_error_type;
typedef struct {
  cw_error_type error;
  const char *message; /* if error but this NULL, parsing/alloc error */
  char needs_free;
} cw_error;
#endif
EOF
my $HBODY_GLOBAL = <<'EOF';
cw_error cw_Mat_pdlDims(MatWrapper *wrapper, int *t, ptrdiff_t *l, ptrdiff_t *c, ptrdiff_t *r);
cw_error cw_Mat_newWithDims(MatWrapper **cw_retval, const ptrdiff_t planes, const ptrdiff_t cols, const ptrdiff_t rows, const int type, void * data);
cw_error cw_Mat_ptr(void **cw_retval, MatWrapper *self);
EOF
my $HFOOTER = <<'EOF';
#ifdef __cplusplus
}
#endif
#endif
EOF

sub gen_gettype {
  my @specs = map [
    $_->numval, $_->integer ? ($_->unsigned ? 'U' : 'S') : 'F', 8*howbig($_)
  ], @PDLTYPES_SUPPORTED;
  <<EOF;
int get_pdltype(const int cvtype) {
  switch (CV_MAT_DEPTH(cvtype)) {
    @{[join "\n    ", map "case CV_$_->[2]$_->[1]: return $_->[0]; break;", @specs]}
  }
  return -1;
}
int get_ocvtype(const int datatype,const int planes) {
  switch (datatype) {
    @{[join "\n    ", map "case $_->[0]: return CV_$_->[2]$_->[1]C(planes); break;", @specs]}
  }
  return -1;
}
EOF
}

sub gen_code {
	my ($class, $name, $doc, $ismethod, $ret, @params) = @_;
	my $ptr_only = $ptr_only{$class};
	die "No class given for method='$ismethod'" if !$class and $ismethod;
	$ret = $type_overrides{$ret}[1] if $type_overrides{$ret};
	my $opt = $overrides{$class}{$name} || {};
	my (@input_args, @cvargs, $methodvar);
	my ($func_ret, $cpp_ret, $after_ret) = ($ret, '', '');
	if ($ret =~ /^[A-Z]/) {
		$func_ret = "${ret}Wrapper *";
		$cpp_ret = "cv::$ret cpp_retval = ";
		$after_ret = "  cw_${ret}_new(cw_retval, NULL); (*cw_retval)->held = cpp_retval;\n";
	} elsif ($ret ne 'void') {
		$cpp_ret = "*cw_retval = ";
	}
	die "Error: '$name' no return type from '$ret'".do {require Data::Dumper; Data::Dumper::Dumper(\@_)} if $ret ne 'void' and !$func_ret;
	push @input_args, "$func_ret*cw_retval" if $ret ne 'void';
	if ($ismethod) {
		push @input_args, "${class}Wrapper *self";
		$methodvar = 'self';
	}
	while (@params) {
		my ($s, $v) = @{shift @params};
		my $was_ptr = $s =~ /^[A-Z]/ ? $s =~ s/\s*\*+$// : 0;
		$s = $type_overrides{$s}[1] if $type_overrides{$s};
		my $ctype = $s . ($s =~ /^[A-Z]/ ? "Wrapper *" : '');
		push @input_args, "$ctype $v";
		push @cvargs, $s =~ /^[A-Z]/ ? ($was_ptr ? '&' : '')."$v->held" : $v;
	}
	my $fname = join '_', grep length, 'cw', $class, $name;
	my $str = "cw_error $fname(" . join(", ", @input_args) . ")";
	my $hstr = $str.";\n";
	$str .= " {\n";
	$str .= " cw_error CW_err = {CW_ENONE, NULL, 0};\n try {\n";
	$str .= "  // pre:\n$$opt{pre}\n" if $$opt{pre};
	$str .= "  $cpp_ret".($ret eq 'char *' ? "strdup(" : "");
	$str .= $ismethod == 0 ? join('::', grep length, "cv", $class, $name)."(" :
	  "$methodvar->held".($ptr_only?'->':'.')."$name" .
	  ($ismethod == 1 ? "(" : ";\n");
	$opt->{argfix}->(\@cvargs) if $opt->{argfix};
	$str .= join(', ', @cvargs).")".($ret eq 'char *' ? ".c_str())" : "").";\n";
	$str .= $after_ret;
	$str .= "  // post:\n$$opt{post}\n" if $$opt{post};
	$str .= " } $CATCH\n return CW_err;\n";
	$str .= "}\n\n";
	return ($hstr,$str);
}

sub gen_wrapper {
  my ($class, @dims) = @_;
  my $ptr_only = $ptr_only{$class};
  my $wrapper = "${class}Wrapper";
  my $hstr = <<EOF;
typedef struct $wrapper $wrapper;
#ifdef __cplusplus
struct $wrapper {
	@{[$ptr_only ? "cv::Ptr<cv::${class}>" : "cv::${class}"]} held;
};
#endif
cw_error cw_${class}_new($wrapper **cw_retval, char *klass@{[
  map ", @$_", @{$extra_cons_args{$class} || []}
]});
void cw_${class}_DESTROY($wrapper *wrapper);
EOF
  my $cstr = <<EOF;
@{[$ptr_only ? '' : "cw_error cw_${class}_new($wrapper **cw_retval, char *klass) {
 cw_error CW_err = {CW_ENONE, NULL, 0};
 try {
  *cw_retval = new $wrapper;
 } $CATCH
 return CW_err;
}"]}
void cw_${class}_DESTROY($wrapper * wrapper) {
	delete wrapper;
}
EOF
  if (@dims) {
    $hstr .= <<EOF;
cw_error cw_${class}_newWithVals($wrapper **cw_retval, @{[join ',', map "@$_[0,1]", @dims]});
cw_error cw_${class}_getVals($wrapper * wrapper,@{[join ',', map "$_->[0] *$_->[1]", @dims]});
EOF
    $cstr .= <<EOF;
cw_error cw_${class}_newWithVals($wrapper **cw_retval, @{[join ',', map "@$_[0,1]", @dims]}) {
 cw_error CW_err = {CW_ENONE, NULL, 0};
 try {
  *cw_retval = new $wrapper;
  (*cw_retval)->held = cv::${class}(@{[join ',', map $_->[1], @dims]});
 } $CATCH
 return CW_err;
}
cw_error cw_${class}_getVals($wrapper *self, @{[join ',', map "$_->[0] *$_->[1]", @dims]}) {
 cw_error CW_err = {CW_ENONE, NULL, 0};
 try {
  @{[join "\n  ", map "*$_->[1] = self->held.@{[$_->[2]||$_->[1]]};", @dims]}
 } $CATCH
 return CW_err;
}
EOF
  }
  $cstr .= $constructor_override{$class} || '';
  ($hstr, $cstr);
}

sub gen_const {
  my ($text, $args) = @_;
  (my $funcname = $text) =~ s#cv::##;
  $funcname =~ s#::#_#g;
  my $t = "int cw_const_$funcname(@{[$args || '']})";
  ("$t;\n", "$t { return (int)$text@{[$args ? '('.join(',',map +(split ' ')[-1], split /\s*,\s*/, $args).')' : '']}; }\n");
}

sub gen_chfiles {
  my ($macro, $extras, $typespecs, $cvheaders, $funclist, $consts, @params) = @_;
  my $hstr = sprintf $HHEADER, $macro;
  my $cstr = join '', map "#include <opencv2/$_.hpp>\n", @{$cvheaders||[]};
  $cstr .= $CHEADER;
  for (sort keys %$typespecs) {
    my ($xhstr, $xcstr) = gen_wrapper($_, @{$typespecs->{$_}});
    $hstr .= $xhstr; $cstr .= $xcstr;
  }
  $hstr .= $extras->[0] || '';
  $cstr .= $extras->[1] || '';
  for my $func (@{$funclist||[]}) {
    my ($xhstr, $xcstr) = gen_code( @$func );
    $hstr .= $xhstr; $cstr .= $xcstr;
  }
  for my $c (@{$consts||[]}) {
    my ($xhstr, $xcstr) = gen_const(@$c);
    $hstr .= $xhstr; $cstr .= $xcstr;
  }
  $hstr .= $HFOOTER;
  $cstr .= $CFOOTER;
  ($hstr, $cstr);
}

sub gen_consts {
  my @consts;
  open my $consts, '<', 'constlist.txt' or die "constlist.txt: $!";
  while (!eof $consts) {
    chomp(my $line = <$consts>);
    push @consts, [split /\|/, $line];
  }
  \@consts;
}

sub make_chfiles {
  my ($filebase, @params) = @_;
  my ($hstr, $cstr) = gen_chfiles(uc($filebase), @params);
  writefile("$filebase.h", $hstr); writefile("$filebase.cpp", $cstr);
}
sub writefile {
  my ($file, $new) = @_;
  my $old = -f $file ? do { local $/; open my $fh, '<', $file or die "$file: $!"; <$fh> } : '';
  return if $new eq $old;
  open my $fh, ">", $file or die "cannot write $file: $!";
  print $fh $new;
}

my $filegen = $ARGV[0] || die "No file given";
my $extras = $filegen eq 'opencv_wrapper' ? [$HBODY_GLOBAL,gen_gettype().$CBODY_GLOBAL] : [qq{#include "opencv_wrapper.h"\n},""];
my $typespec = $filegen eq 'opencv_wrapper' ? \%GLOBALTYPES : !-f 'classes.pl' ? +{} : do {
  my @classlist = do ''. catfile curdir, 'classes.pl'; die if $@;
  +{map +($_->[0]=>[]), @classlist}
};
my @cvheaders = grep length, split /,/, $ARGV[1]||'';
my $funclist = $filegen eq 'opencv_wrapper' ? [] : \@funclist;
my $consts = $filegen eq 'opencv_wrapper' ? [] : -f 'constlist.txt' ? gen_consts() : [];
make_chfiles($filegen, $extras, $typespec, \@cvheaders, $funclist, $consts);

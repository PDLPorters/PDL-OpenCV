use strict;
use warnings;
use FindBin qw($Bin);
use File::Spec::Functions;
use PDL::Types;
use PDL::Core qw/howbig/;

require ''. catfile $Bin, 'genpp.pl';
our (%type_overrides, %type_alias, %extra_cons_args, %STAYWRAPPED);
my %GLOBALTYPES = do { no warnings 'once'; (%PP::OpenCV::DIMTYPES, map +($_=>[]), keys %STAYWRAPPED) };
my @PDLTYPES_SUPPORTED = grep $_->real && $_->ppsym !~/[KPQN]/ && howbig($_) <= 8, PDL::Types::types;
my %REALCTYPE2NUMVAL = map +($_->realctype=>$_->numval), PDL::Types::types;
my %VECTORTYPES = (%GLOBALTYPES, map +($_=>[]), qw(int float double uchar));
my %overrides = (
  Tracker => {
    update => {pre=>'TRACKER_RECT_TYPE box;',post=>'boundingBox->held = box;',argfix=>sub{$_[0][1]='box'}},
  },
);
my %ptr_only = map +($_=>1), qw(Tracker LineSegmentDetector);
my $wrap_re = qr/^(?:(?!String)[A-Z]|vector_)/;
my %constructor_override = (
  Tracker => <<EOF,
#if CV_VERSION_MINOR >= 5 && CV_VERSION_MAJOR >= 4
# define TRACKER_RECT_TYPE cv::Rect
#else
# define TRACKER_RECT_TYPE cv::Rect2d
#endif
cw_error cw_Tracker_new(TrackerWrapper **cw_retval, char *klass) {
 TRY_WRAP((*cw_retval = new TrackerWrapper)->held = cv::TrackerKCF::create();)
}
EOF
  LineSegmentDetector => <<EOF,
cw_error cw_LineSegmentDetector_new(LineSegmentDetectorWrapper **cw_retval, char *klass, int lsd_type) {
 TRY_WRAP(
  (*cw_retval = new LineSegmentDetectorWrapper)->held = cv::createLineSegmentDetector(lsd_type);
 )
}
EOF
  String => <<EOF,
cw_error cw_String_new(StringWrapper **cw_retval, char *klass, const char* str) {
 TRY_WRAP(
  (*cw_retval = new StringWrapper)->held = str ? cv::String(str) : cv::String();
 )
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
 TRY_WRAP(
  char isempty = (planes == 0 && cols == 0 && rows == 0);
  if (!isempty && !data) throw std::invalid_argument("NULL data passed to cw_Mat_newWithDims");
  (*cw_retval = new MatWrapper)->held = isempty ? cv::Mat() : /* no check type as upgrade */
   cv::Mat(rows, cols, get_ocvtype(type,planes), data);
 )
}
cw_error cw_Mat_pdlDims(MatWrapper *wrapper, int *t, ptrdiff_t *l, ptrdiff_t *c, ptrdiff_t *r) {
 TRY_WRAP(
  *t = get_pdltype(wrapper->held.type());
  *l = wrapper->held.channels();
  *c = wrapper->held.cols;
  *r = wrapper->held.rows;
 )
}
cw_error cw_Mat_copyDataTo(MatWrapper *self, void *data, ptrdiff_t bytes) {
 ptrdiff_t shouldbe = self->held.elemSize() * self->held.cols * self->held.rows;
 SHOULDBE_CHECK(bytes, shouldbe)
 TRY_WRAP( memmove(data, self->held.ptr(), bytes); )
}
cw_error cw_String_c_str(const char **ptr, StringWrapper *self) {
 TRY_WRAP( *ptr = self->held.c_str(); )
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
#define TRY_WRAP(...) \
 cw_error CW_err = {CW_ENONE, NULL, 0}; \
 try { \
  __VA_ARGS__ \
 } catch (const std::exception& e) { \
  CW_err = {CW_EUSERERROR,strdup(e.what()),1}; \
 } \
 return CW_err;
#define SHOULDBE_CHECK(got, expected) \
 if (got != expected) { \
  char buf[100]; \
  snprintf(buf, sizeof(buf), "copyDataTo: wrong number of bytes passed; expected %td, passed %td", expected, got); \
  return {CW_EUSERERROR,strdup(buf),1}; \
 }
cw_error cw_Mat_pdlDims(MatWrapper *wrapper, int *t, ptrdiff_t *l, ptrdiff_t *c, ptrdiff_t *r);
cw_error cw_Mat_newWithDims(MatWrapper **cw_retval, const ptrdiff_t planes, const ptrdiff_t cols, const ptrdiff_t rows, const int type, void * data);
cw_error cw_Mat_copyDataTo(MatWrapper *self, void *data, ptrdiff_t bytes);
cw_error cw_String_c_str(const char **ptr, StringWrapper *self);
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
	$name = [$name, $name] if !ref $name;
	my ($in_name, $out_name) = @$name;
	my $ptr_only = $ptr_only{$class};
	die "No class given for method='$ismethod'" if !$class and $ismethod;
	$ret = $type_overrides{$ret}[1] if $type_overrides{$ret};
	my $opt = $overrides{$class}{$in_name} || {};
	my (@input_args, @cvargs, $methodvar);
	my ($func_ret, $cpp_ret, $after_ret) = ($ret, '', '');
	if ($ret eq 'StringWrapper*') {
		$func_ret = "StringWrapper *";
		$cpp_ret = "cv::String cpp_retval = ";
		$after_ret = "  CW_err = cw_String_new(cw_retval, NULL, cpp_retval.c_str()); if (CW_err.error) return CW_err;\n";
	} elsif ($ret =~ $wrap_re) {
		$func_ret = "${ret}Wrapper *";
		$cpp_ret = "cv::$ret cpp_retval = ";
		$after_ret = "  CW_err = cw_${ret}_new(cw_retval, NULL); if (CW_err.error) return CW_err; (*cw_retval)->held = cpp_retval;\n";
	} elsif ($ret ne 'void') {
		$cpp_ret = "*cw_retval = ";
	}
	die "Error: '$out_name' no return type from '$ret'".do {require Data::Dumper; Data::Dumper::Dumper(\@_)} if $ret ne 'void' and !$func_ret;
	push @input_args, "$func_ret*cw_retval" if $ret ne 'void';
	if ($ismethod) {
		push @input_args, "${class}Wrapper *self";
		$methodvar = 'self';
	}
	while (@params) {
		my ($s, $v) = @{shift @params};
		my $was_ptr = $s =~ $wrap_re ? $s =~ s/\s*\*+$// : 0;
		$s = $type_overrides{$s}[1] if $type_overrides{$s};
		$s = $1.$type_alias{$2} if $s =~ /^(vector_)(.*)/ and $type_alias{$2};
		my $ctype = $s . ($s =~ $wrap_re ? "Wrapper *" : '');
		push @input_args, "$ctype $v";
		push @cvargs, $s eq 'StringWrapper*' ? "$v->held" : $s =~ $wrap_re ? ($was_ptr ? '&' : '')."$v->held" : $v;
	}
	my $fname = join '_', grep length, 'cw', $class, $out_name;
	my $str = "cw_error $fname(" . join(", ", @input_args) . ")";
	my $hstr = $str.";\n";
	$str .= " {\n";
	$str .= " TRY_WRAP(\n";
	$str .= "  // pre:\n$$opt{pre}\n" if $$opt{pre};
	$str .= "  $cpp_ret";
	$str .= $ismethod == 0 ? join('::', grep length, "cv", $class, $in_name)."(" :
	  "$methodvar->held".($ptr_only?'->':'.')."$in_name" .
	  ($ismethod == 1 ? "(" : ";\n");
	$opt->{argfix}->(\@cvargs) if $opt->{argfix};
	$str .= join(', ', @cvargs).");\n";
	$str .= $after_ret;
	$str .= "  // post:\n$$opt{post}\n" if $$opt{post};
	$str .= " )\n";
	$str .= "}\n\n";
	return ($hstr,$str);
}

sub gen_wrapper {
  my ($class, $is_vector, @fields) = @_;
  my $ptr_only = $ptr_only{$class};
  my $vector_str = 'vector_' x $is_vector;
  my $vector2_str = $is_vector > 1 ? 'vector_' x ($is_vector-1) : '';
  my $wrapper = "$vector_str${class}Wrapper";
  my %tdecls = (
    new => qq{cw_error cw_$vector_str${class}_new($wrapper **cw_retval, char *klass@{[
      map ", @$_", @{$is_vector ? [] : $extra_cons_args{$class} || []}
    ]})},
    dest => qq{void cw_$vector_str${class}_DESTROY($wrapper *wrapper)},
    dim0 => qq{ptrdiff_t cw_$vector_str${class}_dim0()},
    pdlt => qq{int cw_$vector_str${class}_pdltype()},
  );
  my $hstr = <<EOF . join '', map "$_;\n", @tdecls{sort keys %tdecls};
typedef struct $wrapper $wrapper;
#ifdef __cplusplus
struct $wrapper {
	@{[$ptr_only ? "cv::Ptr<cv::${class}>" :
	  !$is_vector ? "cv::${class}" :
	  ("std::vector<"x$is_vector)."@{[@fields || $STAYWRAPPED{$class} ? qq{cv::$class} : $class]}".(">"x$is_vector)
	]} held;
};
#endif
EOF
  my $cstr = <<EOF;
@{[$constructor_override{$class} && !$is_vector ? '' : "$tdecls{new} {
 TRY_WRAP( *cw_retval = new $wrapper; )
}"]}
$tdecls{dest} {
	delete wrapper;
}
$tdecls{dim0} { return @{[0+@fields]}; }
$tdecls{pdlt} { return @{[
  @fields ? $REALCTYPE2NUMVAL{$fields[0][0]} :
  $REALCTYPE2NUMVAL{$type_overrides{$class} ? $type_overrides{$class}[1] : $class} // '-1'
]}; }
EOF
  if ($is_vector) {
    my $underlying_type = $is_vector > 1 ? "$vector2_str${class}Wrapper*" :
      @fields ? $fields[0][0] :
      $STAYWRAPPED{$class} ? "${class}Wrapper*" :
      $type_overrides{$class} ? $type_overrides{$class}[1] :
      $class;
    my %decls = (
      nWV => qq{cw_error cw_$vector_str${class}_newWithVals($wrapper **cw_retval, $underlying_type *data, ptrdiff_t count)},
      size => "cw_error cw_$vector_str${class}_size(ptrdiff_t *count, $wrapper *self)",
      cDT => "cw_error cw_$vector_str${class}_copyDataTo($wrapper *self, $underlying_type *data@{[$is_vector > 1 || $STAYWRAPPED{$class} ? '' : ', ptrdiff_t bytes']})",
    );
    $hstr .= join '', map "$_;\n", @decls{sort keys %decls};
    my $field_count = 0;
    $cstr .= <<EOF;
$decls{nWV} {
 TRY_WRAP(
  *cw_retval = new $wrapper;
  (*cw_retval)->held = @{["std::vector<"x$is_vector]}@{[@fields || $STAYWRAPPED{$class} ? qq{cv::$class} : $class]}@{[">"x$is_vector]}@{[
    $is_vector <= 1 && !@fields && !$STAYWRAPPED{$class} ? "(data, data + count);" :
    join "\n  ", "(count);",
      "ptrdiff_t i = 0, stride = @{[$is_vector > 1 ? 1 : 0+@fields]};",
      "for (i = 0; i < count; i++)",
      "  (*cw_retval)->held[i] = ".($is_vector > 1 || $STAYWRAPPED{$class} ? 'data[i]->held' : "cv::$class(".join(',', map "data[i*stride + ".$field_count++."]", @fields).")").";",
  ]}
 )
}
$decls{size} {
 TRY_WRAP( *count = self->held.size(); )
}
$decls{cDT} {
 ptrdiff_t i = 0, stride = @{[$is_vector > 1 ? 1 : (0+@fields) || 1]}, count = self->held.size();
 @{[$is_vector > 1 || $STAYWRAPPED{$class} ? "" :
 "ptrdiff_t shouldbe = sizeof($underlying_type) * stride * count;
 SHOULDBE_CHECK(bytes, shouldbe)"]}
 TRY_WRAP(
  @{[$is_vector <= 1 && !@fields && !$STAYWRAPPED{$class} ? 'memmove(data, self->held.data(), bytes);' :
  $STAYWRAPPED{$class} || $is_vector > 1 ? qq{for (i = 0; i < count; i++)
    (data[i] = new $vector2_str${class}Wrapper)->held = self->held[i];}:
  join "\n  ",
    do {$field_count = 0; ()},
    "for (i = 0; i < count; i++) {",
    (map "  data[i*stride + ".$field_count++."] = self->held[i].@{[$_->[2]||$_->[1]]};", @fields),
    "}",
  ]}
 )
}
EOF
  } elsif (@fields) {
    my %decls = (
      nWV => qq{cw_error cw_$vector_str${class}_newWithVals($wrapper **cw_retval, @{[join ',', map "@$_[0,1]", @fields]})},
      gV => qq{cw_error cw_$vector_str${class}_getVals($wrapper *self,@{[join ',', map "$_->[0] *$_->[1]", @fields]})},
    );
    $hstr .= join '', map "$_;\n", @decls{sort keys %decls};
    $cstr .= <<EOF;
$decls{nWV} {
 TRY_WRAP(
  (*cw_retval = new $wrapper)->held = cv::${class}(@{[join ',', map $_->[1], @fields]});
 )
}
$decls{gV} {
 TRY_WRAP(
  @{[join "\n  ", map "*$_->[1] = self->held.@{[$_->[2]||$_->[1]]};", @fields]}
 )
}
EOF
  }
  $cstr .= $constructor_override{$class} || '' if !$is_vector;
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
  my ($macro, $extras, $typespecs, $vectorspecs, $cvheaders, $funclist, $consts, @params) = @_;
  my $hstr = sprintf $HHEADER, $macro;
  my $cstr = join '', map "#include <opencv2/$_.hpp>\n", @{$cvheaders||[]};
  $cstr .= $CHEADER;
  for (sort keys %$typespecs) {
    my ($xhstr, $xcstr) = gen_wrapper($_, 0, @{$typespecs->{$_}});
    $hstr .= $xhstr; $cstr .= $xcstr;
  }
  for (sort keys %$vectorspecs) {
    my ($xhstr, $xcstr) = gen_wrapper($_, 1, @{$vectorspecs->{$_}});
    $hstr .= $xhstr; $cstr .= $xcstr;
    ($xhstr, $xcstr) = gen_wrapper($_, 2, @{$vectorspecs->{$_}});
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
my $vectorspecs = $filegen eq 'opencv_wrapper' ? \%VECTORTYPES : +{};
my @cvheaders = grep length, split /,/, $ARGV[1]||'';
my $funclist = $filegen eq 'opencv_wrapper' ? [] : \@funclist;
my $consts = $filegen eq 'opencv_wrapper' ? [] : -f 'constlist.txt' ? gen_consts() : [];
make_chfiles($filegen, $extras, $typespec, $vectorspecs, \@cvheaders, $funclist, $consts);

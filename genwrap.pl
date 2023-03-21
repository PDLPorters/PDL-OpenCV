use strict;
use warnings;
use FindBin qw($Bin);
use File::Spec::Functions;
use PDL::Types;
use PDL::Core qw/howbig/;
use Config;

require ''. catfile $Bin, 'genpp.pl';
our (%type_overrides, %type_alias, %STAYWRAPPED);
my %GLOBALTYPES = do { no warnings 'once'; (%PP::OpenCV::DIMTYPES, map +($_=>[]), keys %STAYWRAPPED) };
my @PDLTYPES_SUPPORTED = grep $_->real && $_->ppsym !~/[KPQN]/ && howbig($_) <= 8, PDL::Types::types;
my %REALCTYPE2NUMVAL = (
  int => PDL::Type->new($Config{intsize} == 4 ? 'long' :
    $Config{intsize} == 8 ? 'longlong' :
    die "Unknown intsize $Config{intsize}"
  )->numval,
  map +($_->realctype=>$_->numval), PDL::Types::types
);
my %VECTORTYPES = (%GLOBALTYPES, map +($_=>[]), qw(int float double uchar));
my $wrap_re = qr/^(?:(?!String)[A-Z]|vector_)/;
my %extra_cons_args = (
  String => [['const char*', 'str']],
);
my %constructor_override = (
  String => "str ? cv::String(str) : cv::String();"
);
my @funclist = do ''. catfile curdir, 'funclist.pl'; die if $@;
my $CHEADER = <<'EOF';
#include "opencv_wrapper.h"
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
EOF
my $HTOP_GLOBAL = <<'EOF';
#include <stddef.h>
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
EOF
my $HBODY_GLOBAL = <<'EOF';
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

sub code_type {
  my ($intype, $v) = @_;
  my $is_vector = (my $no_vector = $intype) =~ s/vector_//g;
  my $cpptype = $no_vector eq 'StringWrapper*' || $no_vector eq 'String' ? 'cv::String' : $no_vector;
  $cpptype = qq{cv::$cpptype} if $cpptype =~ $wrap_re;
  $cpptype = ("std::vector<"x$is_vector).$cpptype.(">"x$is_vector)
    if $is_vector;
  my $was_ptr = $intype =~ $wrap_re ? ($intype =~ s/\s*\*+$// || $intype =~ s/^Ptr_//) : 0;
  $intype = $type_overrides{$intype}[1] if $type_overrides{$intype};
  $intype = ('vector_'x$is_vector).$type_alias{$no_vector} if $is_vector and $type_alias{$no_vector};
  my $nowrapper = $intype;
  $intype .= "Wrapper*" if $intype =~ $wrap_re;
  my $no_ptr = $is_vector || $PP::OpenCV::DIMTYPES{$nowrapper} || $STAYWRAPPED{$nowrapper};
  $intype = "$intype *" if $was_ptr and $intype !~ $wrap_re;
  my $cpp_input = $intype eq 'StringWrapper*' ? "$v->held" :
    $nowrapper =~ $wrap_re ? ($was_ptr ? '&' : '')."$v->held".(
      $no_ptr ? "" : "[0]"
    ) : $v;
  ($no_ptr, $intype, $cpptype, $cpp_input);
}

sub gen_code {
	my ($ptr_only, $class, $name, $doc, $ismethod, $ret, @params) = @_;
	$name = [$name, $name] if !ref $name;
	my ($in_name, $out_name) = @$name;
	die "No class given for '$name' method='$ismethod'" if !$class and $ismethod;
	$ret = $type_overrides{$ret}[1] if $type_overrides{$ret};
	my ($no_ptr, $func_ret, $cpptype) = code_type($ret, 'ret');
	my $after_ret = $ret eq 'StringWrapper*' ? "  CW_err = cw_String_new(cw_retval, NULL, cpp_retval.c_str()); if (CW_err.error) return CW_err;\n" :
	  $ret =~ $wrap_re ? "  CW_err = cw_${ret}_new(cw_retval, NULL); if (CW_err.error) return CW_err; (*cw_retval)->held = ".(
	    $no_ptr ? "cpp_retval" : "cv::Ptr<$cpptype>(&cpp_retval)"
	  ).";\n" : '';
	my $cpp_ret = $ret eq 'void' ? '' :
	  ($ret eq 'StringWrapper*' || $ret =~ $wrap_re) ? "$cpptype cpp_retval = " :
	 "*cw_retval = ";
	die "Error: '$out_name' no return type from '$ret'".do {require Data::Dumper; Data::Dumper::Dumper(\@_)} if $ret ne 'void' and !$func_ret;
	my @input_args = $ret ne 'void' ? "$func_ret*cw_retval" : ();
	push @input_args, "${class}Wrapper *self" if $ismethod;
	push @input_args, map +(code_type(@$_))[1]." $_->[1]", @params;
	my $fname = join '_', grep length, 'cw', $class, $out_name;
	my $str = "cw_error $fname(" . join(", ", @input_args) . ")";
	my $hstr = $str.";\n";
	$str .= " {\n";
	$str .= " TRY_WRAP(\n";
	$str .= "  $cpp_ret";
	$str .= !$ismethod ? join('::', grep length, "cv", $class, $in_name) :
	  "self->held->$in_name";
	$str .= "(".join(', ', map +(code_type(@$_))[3], @params).");\n";
	$str .= $after_ret;
	$str .= " )\n";
	$str .= "}\n\n";
	return ($hstr,$str);
}

sub gen_wrapper {
  my ($ptr_only, $cons_func, $extra_args, $class, $is_vector, @fields) = @_;
  my $vector_str = 'vector_' x $is_vector;
  my $vector2_str = $is_vector > 1 ? 'vector_' x ($is_vector-1) : '';
  my $wrapper = "$vector_str${class}Wrapper";
  my $need_cv = @fields || $STAYWRAPPED{$class};
  my $vector_class = ("std::vector<"x$is_vector).($need_cv ? qq{cv::$class} : $class).(">"x$is_vector);
  my %tdecls_all = (
    dim0 => qq{ptrdiff_t cw_$vector_str${class}_dim0()},
    pdlt => qq{int cw_$vector_str${class}_pdltype()},
  );
  my $hstr = <<EOF . join '', map "$_;\n", @tdecls_all{sort keys %tdecls_all};
typedef struct $wrapper $wrapper;
#ifdef __cplusplus
struct $wrapper {
	@{[
	  $is_vector ? $vector_class :
	  $need_cv ? "cv::${class}" : "cv::Ptr<cv::${class}>"
	]} held;
};
#endif
EOF
  my $cstr = <<EOF;
$tdecls_all{dim0} { return @{[0+@fields]}; }
$tdecls_all{pdlt} { return @{[
  @fields ? $REALCTYPE2NUMVAL{$fields[0][0]} // die "Unknown ctype '$fields[0][0]' for '$class'" :
  $REALCTYPE2NUMVAL{$type_overrides{$class} ? $type_overrides{$class}[1] : $class} // '-1'
]}; }
EOF
  if ($is_vector || defined $cons_func) {
    my $dest_decl = "void cw_$vector_str${class}_DESTROY($wrapper *wrapper)";
    $hstr .= "$dest_decl;\n";
    $cstr .= qq{$dest_decl { delete wrapper; }\n};
    my $no_ptr = $is_vector || $need_cv;
    my $use_override = $constructor_override{$class} && !$is_vector;
    my $new_decl = qq{cw_error cw_$vector_str${class}_new($wrapper **cw_retval, char *klass@{[
	join '', map ", ".(code_type(@$_))[1]." $_->[1]", @$extra_args
      ]})};
    $hstr .= "$new_decl;\n";
    $cstr .= "$new_decl {\n TRY_WRAP(";
    $cstr .= $no_ptr && !$use_override ? " *cw_retval = new $wrapper;" :
      "\n  (*cw_retval = new $wrapper)->held = ".
      ($use_override ? "$constructor_override{$class}\n" :
	($ptr_only ? '' : qq{cv::makePtr<}).$cons_func.($ptr_only ? '' : qq{>}).
	"(@{[ join ', ', map +(code_type(@$_))[3], @$extra_args ]});\n");
    $cstr .= " )\n}\n";
  }
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
  (*cw_retval = new $wrapper)->held = $vector_class@{[
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
 SHOULDBE_CHECK(bytes, shouldbe)\n"
]} TRY_WRAP(
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
  my $hstr = sprintf($HHEADER, $macro) . $extras->[0];
  my $cstr = join '', (map "#include <opencv2/$_.hpp>\n", qw(opencv core/utility), @{$cvheaders||[]}), $extras->[2];
  $cstr .= $CHEADER;
  my %po;
  for (sort keys %$typespecs) {
    my ($fields, $po, $cf, $xa) = @{$typespecs->{$_}};
    my ($xhstr, $xcstr) = gen_wrapper($po{$_} = $po, $cf, ($xa||[[[]]])->[0][0], $_, 0, @$fields);
    $hstr .= $xhstr; $cstr .= $xcstr;
  }
  for (sort keys %$vectorspecs) {
    my ($xhstr, $xcstr) = gen_wrapper($po{$_}, undef, [], $_, 1, @{$vectorspecs->{$_}});
    $hstr .= $xhstr; $cstr .= $xcstr;
    ($xhstr, $xcstr) = gen_wrapper($po{$_}, undef, [], $_, 2, @{$vectorspecs->{$_}});
    $hstr .= $xhstr; $cstr .= $xcstr;
  }
  $hstr .= $extras->[1] || '';
  $cstr .= $extras->[3] || '';
  for my $func (@{$funclist||[]}) {
    my ($xhstr, $xcstr) = gen_code($po{$func->[0]}, @$func);
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

sub readclasses {
  return +{} if !-f 'classes.pl';
  my @classlist = do ''. catfile curdir, 'classes.pl'; die if $@;
  +{map +($_->[0]=>[
    [], @$_[3..5],
  ]), @classlist
  };
}

my $filegen = $ARGV[0] || die "No file given";
my @cvheaders = grep length, split /,/, $ARGV[1]||'';
my $cons_arg = $ARGV[2] // '';
my $extras = $filegen eq 'opencv_wrapper' ? [$HTOP_GLOBAL,$HBODY_GLOBAL,"",gen_gettype().$CBODY_GLOBAL] : [qq{#include "opencv_wrapper.h"\n},"",qq{#include "wraplocal.h"\n},""];
my $localclasses = readclasses();
my $globalclasses = +{ (map +($_=>[$GLOBALTYPES{$_}, undef, "cv::$_", [[$extra_cons_args{$_}]]]), keys %GLOBALTYPES), %$localclasses };
my $typespec = $filegen eq 'opencv_wrapper' ? $globalclasses : $cons_arg eq 'nocons' ? +{} : $localclasses;
my $vectorspecs = $filegen eq 'opencv_wrapper' ? \%VECTORTYPES : +{};
my $funclist = $filegen eq 'opencv_wrapper' ? [] : \@funclist;
my $consts = $filegen eq 'opencv_wrapper' ? [] : -f 'constlist.txt' ? gen_consts() : [];
make_chfiles($filegen, $extras, $typespec, $vectorspecs, \@cvheaders, $funclist, $consts);

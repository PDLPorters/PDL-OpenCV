use strict;
use warnings;
use FindBin qw($Bin);
use File::Spec::Functions;
use PDL::Types;
use PDL::Core qw/howbig/;

require ''. catfile $Bin, 'genpp.pl';
our %DIMTYPES;
my %GLOBALTYPES = (%DIMTYPES, Mat=>[]);
my %LOCALTYPES = (VideoCapture=>[], VideoWriter=>[], Tracker=>[1]);
my @funclist = do ''. catfile curdir, 'funclist.pl'; die if $@;
my $CHEADER = <<'EOF';
#include "opencv_wrapper.h"
#include <opencv2/opencv.hpp>
#include <opencv2/core/utility.hpp> /* allows control number of threads */
/* use C name mangling */
extern "C" {
EOF
my $CBODY_GLOBAL = <<'EOF';
MatWrapper * cw_Mat_newWithDims(const ptrdiff_t planes, const ptrdiff_t cols, const ptrdiff_t rows, const int type, void * data) {
	MatWrapper *mw = new MatWrapper;
	mw->held = cv::Mat(rows, cols, get_ocvtype(type,planes), data);
	return mw;
}
void cw_Mat_pdlDims(MatWrapper *wrapper, int *t, ptrdiff_t *l, ptrdiff_t *c, ptrdiff_t *r) {
	*t = get_pdltype(wrapper->held.type());
	*l = wrapper->held.channels();
	*c = wrapper->held.cols;
	*r = wrapper->held.rows;
}
EOF
my $CBODY_LOCAL = <<'EOF';
#if CV_VERSION_MINOR >= 5 && CV_VERSION_MAJOR >= 4
# define TRACKER_RECT_TYPE cv::Rect
#else
# define TRACKER_RECT_TYPE cv::Rect2d
#endif
TrackerWrapper *cw_Tracker_new(char *klass) {
	TrackerWrapper *Tr = new TrackerWrapper;
	Tr->held = cv::TrackerKCF::create();
	return Tr;
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
EOF
my $HBODY_GLOBAL = <<'EOF';
void cw_Mat_pdlDims(MatWrapper *wrapper, int *t, ptrdiff_t *l, ptrdiff_t *c, ptrdiff_t *r);
MatWrapper * cw_Mat_newWithDims(const ptrdiff_t planes, const ptrdiff_t cols, const ptrdiff_t rows, const int type, void * data);
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
  ], grep $_->real && $_->ppsym !~/[KPQN]/ && howbig($_) <= 8, PDL::Types::types;
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
	my ($ptronly, $class, $name, $ismethod, $ret, $opt, @params) = @_;
	die "No class given for method='$ismethod'" if !$class and $ismethod;
	my (@args, @cvargs, $methodvar);
	my $func_ret = $ret =~ /^[A-Z]/ ? "${ret}Wrapper *" : $ret;
	my $cpp_ret = $ret eq 'void' ? '' : ($ret =~ /^[A-Z]/ ? "cv::$ret cpp_" : "$ret ")."retval = ";
	my $after_ret = $ret =~ /^[A-Z]/ ? "  ${func_ret}retval = cw_${ret}_new(NULL); retval->held = cpp_retval;\n" : '';
	if ($ismethod) {
		push @args, "${class}Wrapper *self";
		$methodvar = 'self';
	}
	die "Error on $class/$name: attribute but args\n" if $ismethod == 2 and @params;
	while (@params) {
		my ($s, $v) = @{shift @params};
		my $ctype = $s . ($s =~ /^[A-Z]/ ? "Wrapper *" : '');
		push @args, "$ctype $v";
		push @cvargs, $s =~ /^[A-Z]/ ? "$v->held" : $v;
	}
	my $fname = join '_', grep length, 'cw', $class, $name;
	my $str = "$func_ret $fname(";
	$str .= join(", ", @args) . ")";
	my $hstr = $str.";\n";
	$str .= " {\n";
	$str .= "  // pre:\n$$opt{pre}\n" if $$opt{pre};
	$str .= "  $cpp_ret";
	$str .= $ismethod == 0 ? join('::', grep length, "cv", $class, $name)."(" :
	  "$methodvar->held".($ptronly?'->':'.')."$name" .
	  ($ismethod == 1 ? "(" : ";\n");
	$opt->{argfix}->(\@cvargs) if $opt->{argfix};
	$str .= join(', ', @cvargs).");\n" if $ismethod != 2;
	$str .= $after_ret;
	$str .= "  // post:\n$$opt{post}\n" if $$opt{post};
	$str .= "  return retval;\n" if $ret ne 'void';
	$str .= "}\n\n";
	return ($hstr,$str);
}

sub gen_wrapper {
  my ($class, $ptr_only, $dims) = @_;
  my $hstr = <<EOF;
typedef struct ${class}Wrapper ${class}Wrapper;
${class}Wrapper *cw_${class}_new(char *klass);
void cw_${class}_DESTROY(${class}Wrapper *wrapper);
EOF
  my $cstr = <<EOF;
struct ${class}Wrapper {
	@{[$ptr_only ? "cv::Ptr<cv::${class}>" : "cv::${class}"]} held;
};
@{[$ptr_only ? '' : "${class}Wrapper *cw_${class}_new(char *klass) {
	return new ${class}Wrapper;
}"]}
void cw_${class}_DESTROY(${class}Wrapper * wrapper) {
	delete wrapper;
}
EOF
  if ($dims) {
    $hstr .= <<EOF;
${class}Wrapper *cw_${class}_newWithVals(@{[join ',', map "@$_[0,1]", @$dims]});
void cw_${class}_getVals(${class}Wrapper * wrapper,@{[join ',', map "$_->[0] *$_->[1]", @$dims]});
EOF
    $cstr .= <<EOF;
${class}Wrapper *cw_${class}_newWithVals(@{[join ',', map "@$_[0,1]", @$dims]}) {
  ${class}Wrapper *self = new ${class}Wrapper;
  self->held = cv::${class}(@{[join ',', map $_->[1], @$dims]});
  return self;
}
void cw_${class}_getVals(${class}Wrapper *self, @{[join ',', map "$_->[0] *$_->[1]", @$dims]}) {
  @{[join "\n  ", map "*$_->[1] = self->held.@{[$_->[2]||$_->[1]]};", @$dims]}
}
EOF
  }
  ($hstr, $cstr);
}

sub gen_const {
  my ($args, $text) = @_;
  (my $funcname = $text) =~ s#cv::##;
  my $t = "int cw_const_$funcname(@{[@$args ? join(',',map qq{@$_}, @$args) : '']})";
  ("$t;\n", "$t { return $text@{[@$args ? '('.join(',',map $_->[1], @$args).')' : '']}; }\n");
}

sub gen_chfiles {
  my ($macro, $typespecs, $cvheaders, $funclist, $consts, @params) = @_;
  my $hstr = sprintf $HHEADER, $macro;
  my $cstr = join '', map "#include <opencv2/$_.hpp>\n", @{$cvheaders||[]};
  $cstr .= $CHEADER;
  $cstr .= gen_gettype();
  for (sort keys %$typespecs) {
    my ($xhstr, $xcstr) = gen_wrapper($_, @{$typespecs->{$_}});
    $hstr .= $xhstr; $cstr .= $xcstr;
  }
  $cstr .= $CBODY_GLOBAL . $CBODY_LOCAL;
  $hstr .= $HBODY_GLOBAL;
  for my $func (@{$funclist||[]}) {
    my ($xhstr, $xcstr) = gen_code( $typespecs->{$func->[0]}[0], @$func );
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
  for my $bits (qw(8UC 8SC 16UC 16SC 32SC 32FC 64FC)) {
    for (1..4) {
      push @consts, [[], "CV_$bits$_"];
    }
    push @consts, [[[qw(int n)]], "CV_$bits"];
  }
  open my $consts, '<', 'constlist.txt' or die "constlist.txt: $!";
  while (!eof $consts) {
    chomp(my $line = <$consts>);
    push @consts, [[], "cv::$line"];
  }
  \@consts;
}

sub make_chfiles {
  my ($filebase, @params) = @_;
  open my $fh,">","$filebase.h" or die "cannot write header file: $!";
  open my $fc,">","$filebase.cpp" or die "cannot write C++ file: $!";
  my ($hstr, $cstr) = gen_chfiles(uc($filebase), @params);
  print $fh $hstr; print $fc $cstr;
}

make_chfiles("opencv_wrapper", {%GLOBALTYPES,%LOCALTYPES}, [qw(tracking highgui imgproc videoio)], \@funclist, gen_consts());

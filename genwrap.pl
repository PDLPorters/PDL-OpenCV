use strict;
use warnings;
use FindBin qw($Bin);
use File::Spec::Functions;
use PDL::Types;
use PDL::Core qw/howbig/;

require ''. catfile $Bin, 'genpp.pl';
our %type_overrides;
my %GLOBALTYPES = do { no warnings 'once'; (%PP::OpenCV::DIMTYPES, Mat=>[]) };
my %overrides = (
  Tracker => {
    update => {pre=>'TRACKER_RECT_TYPE box;',post=>'boundingBox->held = box;',argfix=>sub{$_[0][1]='box'}},
  },
);
my %ptr_only = map +($_=>1), qw(Tracker);
my %constructor_override = (
  Tracker => <<'EOF',
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
void * cw_Mat_ptr(MatWrapper *self) { return self->held.ptr(); }
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
void * cw_Mat_ptr(MatWrapper *self);
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
	my ($class, $name, $doc, $ismethod, $ret, @params) = @_;
	my $ptr_only = $ptr_only{$class};
	die "No class given for method='$ismethod'" if !$class and $ismethod;
	$ret = $type_overrides{$ret}[1] if $type_overrides{$ret};
	my $opt = $overrides{$class}{$name} || {};
	my (@args, @cvargs, $methodvar);
	my ($func_ret, $cpp_ret, $after_ret) = ($ret, '', '');
	if ($ret =~ /^[A-Z]/) {
		$func_ret = "${ret}Wrapper *";
		$cpp_ret = "cv::$ret cpp_retval = ";
		$after_ret = "  ${func_ret}retval = cw_${ret}_new(NULL); retval->held = cpp_retval;\n";
	} elsif ($ret ne 'void') {
		$cpp_ret = "$ret retval = ";
	}
	if ($ismethod) {
		push @args, "${class}Wrapper *self";
		$methodvar = 'self';
	}
	while (@params) {
		my ($s, $v) = @{shift @params};
		$s = $type_overrides{$s}[1] if $type_overrides{$s};
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
	  "$methodvar->held".($ptr_only?'->':'.')."$name" .
	  ($ismethod == 1 ? "(" : ";\n");
	$opt->{argfix}->(\@cvargs) if $opt->{argfix};
	$str .= join(', ', @cvargs).");\n";
	$str .= $after_ret;
	$str .= "  // post:\n$$opt{post}\n" if $$opt{post};
	$str .= "  return retval;\n" if $ret ne 'void';
	$str .= "}\n\n";
	return ($hstr,$str);
}

sub gen_wrapper {
  my ($class, @dims) = @_;
  my $ptr_only = $ptr_only{$class};
  my $hstr = <<EOF;
typedef struct ${class}Wrapper ${class}Wrapper;
#ifdef __cplusplus
struct ${class}Wrapper {
	@{[$ptr_only ? "cv::Ptr<cv::${class}>" : "cv::${class}"]} held;
};
#endif
${class}Wrapper *cw_${class}_new(char *klass);
void cw_${class}_DESTROY(${class}Wrapper *wrapper);
EOF
  my $cstr = <<EOF;
@{[$ptr_only ? '' : "${class}Wrapper *cw_${class}_new(char *klass) {
	return new ${class}Wrapper;
}"]}
void cw_${class}_DESTROY(${class}Wrapper * wrapper) {
	delete wrapper;
}
EOF
  if (@dims) {
    $hstr .= <<EOF;
${class}Wrapper *cw_${class}_newWithVals(@{[join ',', map "@$_[0,1]", @dims]});
void cw_${class}_getVals(${class}Wrapper * wrapper,@{[join ',', map "$_->[0] *$_->[1]", @dims]});
EOF
    $cstr .= <<EOF;
${class}Wrapper *cw_${class}_newWithVals(@{[join ',', map "@$_[0,1]", @dims]}) {
  ${class}Wrapper *self = new ${class}Wrapper;
  self->held = cv::${class}(@{[join ',', map $_->[1], @dims]});
  return self;
}
void cw_${class}_getVals(${class}Wrapper *self, @{[join ',', map "$_->[0] *$_->[1]", @dims]}) {
  @{[join "\n  ", map "*$_->[1] = self->held.@{[$_->[2]||$_->[1]]};", @dims]}
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
  open my $fh,">","$filebase.h" or die "cannot write header file: $!";
  open my $fc,">","$filebase.cpp" or die "cannot write C++ file: $!";
  my ($hstr, $cstr) = gen_chfiles(uc($filebase), @params);
  print $fh $hstr; print $fc $cstr;
}

my $filegen = $ARGV[0] || die "No file given";
my $extras = $filegen eq 'opencv_wrapper' ? [$HBODY_GLOBAL,gen_gettype().$CBODY_GLOBAL] : [qq{#include "opencv_wrapper.h"\n},""];
my $typespec = $filegen eq 'opencv_wrapper' ? \%GLOBALTYPES : {map +($_=>[]), @ARGV[2..$#ARGV]};
my @cvheaders = grep length, split /,/, $ARGV[1]||'';
my $funclist = $filegen eq 'opencv_wrapper' ? [] : \@funclist;
my $consts = $filegen eq 'opencv_wrapper' ? [] : -f 'constlist.txt' ? gen_consts() : [];
make_chfiles($filegen, $extras, $typespec, \@cvheaders, $funclist, $consts);

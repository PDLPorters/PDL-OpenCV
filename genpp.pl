use strict;
use warnings;
use PDL::Types;
use File::Spec::Functions qw(catfile curdir);
use File::Basename 'dirname';
require ''. catfile dirname(__FILE__), 'doxyparse.pl';

my $T = [qw(A B S U L F D)];
our %type_overrides = (
  String => ['char *', 'char *'], # PP, C
  bool => ['byte', 'unsigned char'],
);
our $IF_ERROR_RETURN = "if (CW_err.error) return *(pdl_error *)&CW_err";

{
package PP::OpenCV;
our %DIMTYPES = (
  Point2f=>[[qw(float x)], [qw(float y)]],
  Point=>[[qw(ptrdiff_t x)], [qw(ptrdiff_t y)]],
  Rect=>[[qw(ptrdiff_t x)], [qw(ptrdiff_t y)], [qw(ptrdiff_t width)], [qw(ptrdiff_t height)]],
  Scalar=>[[qw(double v0 val[0])], [qw(double v1 val[1])], [qw(double v2 val[2])], [qw(double v3 val[3])]],
  Size=>[[qw(ptrdiff_t width)], [qw(ptrdiff_t height)]],
);
sub new {
  my ($class, $type, $name, $pcount, $is_output) = @_;
  my $self = bless {type=>$type, name=>$name, is_output=>$is_output}, $class;
  @$self{qw(is_other naive_otherpar use_comp)} = (1,1,1), return $self if $type eq 'char *';
  if ($type !~ /^[A-Z]/) {
    (my $pdltype = $type) =~ s#\s*\*+$##;
    @$self{qw(dimless pdltype ctype was_ptr)} = (1, $pdltype, $type, $type ne $pdltype);
    return $self;
  }
  @$self{qw(was_ptr type)} = (1, $type) if $type =~ s/\s*\*+$//;
  %$self = (%$self,
    pcount => $pcount,
    ctype => "${type}Wrapper *",
    pdltype => '',
    fixeddims => 0,
    destroy => "cw_${type}_DESTROY",
    blank => "CW_err = cw_${type}_new(&\$COMP($name), NULL); $IF_ERROR_RETURN",
  );
  if (my $spec = $DIMTYPES{$type}) {
    $self->{fixeddims} = 1;
    $self->{pdltype} = $spec->[0][0] eq 'ptrdiff_t' ? "indx" : $spec->[0][0];
  } elsif ($type ne 'Mat') {
    @$self{qw(is_other use_comp)} = (1,1);
  }
  $self->{use_comp} = 1 if !$self->{dimless} and $is_output and !$self->{fixeddims};
  bless $self, $class;
}
sub c_input {
  my ($self, $compmode) = @_;
  return $self->{use_comp}?"\$COMP($self->{name})":
    $self->{name}.($compmode?'_LOCAL':'')
    if !$self->{dimless};
  ($self->{type} =~ /\*$/ ? '&' : '').
    ($compmode ? "(($self->{pdltype}*)($self->{name}->data))[0]" : "\$$self->{name}()")
}
sub par {
  my ($self) = @_;
  return $self->_par if $self->{is_other};
  join ' ', grep length, $self->{pdltype}, ($self->{is_output} ? '[o]' : ()), $self->_par;
}
sub _par {
  my ($self) = @_;
  return "$self->{name}()" if $self->{dimless};
  return "@$self{qw(type name)}" if $self->{naive_otherpar};
  my ($name, $type, $pcount) = @$self{qw(name type pcount)};
  return "$name(l$pcount,c$pcount,r$pcount)" if $type eq 'Mat';
  return "$name(n${type}$pcount=".scalar(@{$DIMTYPES{$type}}).")" if $self->{fixeddims};
  "PDL__OpenCV__$type $name";
}
sub frompdl {
  my ($self, $iscomp, $localname) = @_;
  my ($name, $type, $pcount) = @$self{qw(name type pcount)};
  return undef if $self->{is_other};
  return "CW_err = cw_Mat_newWithDims(" .
    ($iscomp
      ? join ',', "&$localname", (map "$name->dims[$_]", 0..2), "$name->datatype,$name->data"
      : "&$localname,\$SIZE(l$pcount),\$SIZE(c$pcount),\$SIZE(r$pcount),\$PDL($name)->datatype,\$P($name)"
    ) .
    "); $IF_ERROR_RETURN;\n" if !$self->{fixeddims};
  qq{CW_err = cw_${type}_newWithVals(@{[
      join ',', "&$localname", map $iscomp ? "(($DIMTYPES{$type}[0][0] *)$name->data)[$_]" : "\$$name(n${type}$pcount=>$_)",
        0..@{$DIMTYPES{$type}}-1
    ]})}."; $IF_ERROR_RETURN;\n";
}
sub topdl1 {
  my ($self, $iscomp) = @_;
  my ($name, $type, $pcount) = @$self{qw(name type pcount)};
  return undef if $self->{is_other};
  return
    "CW_err = cw_Mat_pdlDims(".($iscomp ? "\$COMP($name)" : $name).", &\$PDL($name)->datatype, &\$SIZE(l$pcount), &\$SIZE(c$pcount), &\$SIZE(r$pcount)); $IF_ERROR_RETURN;\n"
    if !$self->{fixeddims};
  "";
}
sub topdl2 {
  my ($self, $iscomp) = @_;
  my ($name, $type, $pcount) = @$self{qw(name type pcount)};
  return undef if $self->{is_other};
  return <<EOF if !$self->{fixeddims};
CW_err = cw_Mat_ptr(&vptmp, @{[$iscomp ? "\$COMP($name)" : $name]});
$IF_ERROR_RETURN;
memmove(\$P($name), vptmp, \$PDL($name)->nbytes);
EOF
  qq{CW_err = cw_${type}_getVals(}.($iscomp ? "\$COMP($name)" : $name).qq{,@{[join ',', map "&\$$name(n${type}$pcount=>$_)", 0..@{$DIMTYPES{$type}}-1]}); $IF_ERROR_RETURN;\n};
}
sub destroy_code {
  my ($self, $iscomp) = @_;
  "$self->{destroy}(".(
    !$iscomp ? $self->{name} :
    !$self->{is_output} ? "$self->{name}_LOCAL" : "\$COMP($self->{name})"
  ).");\n";
}
}

sub genpp {
    my ($class,$func,$doc,$ismethod,$ret,@params) = @_;
    die "No class given for method='$ismethod'" if !$class and $ismethod;
    my %hash = (GenericTypes=>$T, NoPthread=>1, HandleBad=>0);
    $hash{PMFunc} = '' if $ismethod;
    my $pcount = 1;
    my $cfunc = join('_', grep length,'cw',$class,$func);
    unshift @params, [$class,'self'] if $ismethod;
    if (!grep /^[A-Z]/ && !PP::OpenCV->new($_, '', 0)->{is_other}, map $_->[0], @params, $ret ne 'void' ? [$type_overrides{$ret} ? $type_overrides{$ret}[0] : $ret] : ()) {
      $ret = $type_overrides{$ret}[1] if $type_overrides{$ret};
      my $doxy = doxyparse($doc);
      $hash{Doc} = doxy2pdlpod($doxy);
      pp_addpm("=head2 $func\n\n$hash{Doc}\n\n=cut\n\n");
      pp_addpm("*$func = \\&${main::PDLOBJ}::$func;\n") if !$ismethod;
      pp_add_exported($func);
      my (@xs_params, @cw_params);
      for (@params) {
        my ($type, $var, $default) = @$_;
        $type = $type_overrides{$type}[1] if $type_overrides{$type};
        my $obj = PP::OpenCV->new($type, $var, 0);
        my $xs_par = ($type =~ /^[A-Z]/ && $obj->{is_other}) ? $obj->par : "$type $var";
        if (length $default and $default !~ /\(/ and $default =~ /[^0-9\.\-]/) {
          $default = 'cw_const_' . $default . '()';
        }
        $xs_par .= "=$default" if length $default;
        push @xs_params, $xs_par;
        push @cw_params, $var;
      }
      unshift @cw_params, '&RETVAL' if $ret ne 'void';
      pp_addxs(<<EOF . ($ret eq 'void' ? '' : "  OUTPUT:\n    RETVAL\n"));
MODULE = ${main::PDLMOD} PACKAGE = ${main::PDLOBJ} PREFIX=@{[join '_', grep length,'cw',$class]}_
\n$ret $cfunc(@{[join ', ', @xs_params]})
  PROTOTYPE: DISABLE
  CODE:
    cw_error CW_err = $cfunc(@{[join ', ', @cw_params]});
    PDL->barf_if_error(*(pdl_error *)&CW_err);
EOF
      return;
    }
    $ret = $type_overrides{$ret}[0] if $type_overrides{$ret};
    push @params, [$ret,'res','',['/O']] if $ret ne 'void';
    my (@allpars, @defaults);
    for (@params) {
      my ($type, $var, $default, $f) = @$_;
      $type = $type_overrides{$type}[0] if $type_overrides{$type};
      $default //= '';
      my %flags = map +($_=>1), @{$f||[]};
      push @allpars, my $obj = PP::OpenCV->new($type, $var, $pcount++, $flags{'/O'});
      die "Error: OtherPars '$var' is output: ".do {require Data::Dumper; Data::Dumper::Dumper($obj)} if $obj->{is_other} and $obj->{is_output};
      $default .= '()' if length $default and $default !~ /\(/ and $default =~ /[^0-9\.\-]/;
      if ($obj->{is_output}) {
        $default = 'PDL->null' if !length $default or ($default eq '0' && $obj->{was_ptr});
      } else {
        $default = 'PDL->zeroes(0,0,0)' if $default eq 'Mat()';
      }
      push @defaults, "\$$var = $default if !defined \$$var;" if length $default;
    }
    my (@pars, @otherpars); push @{$_->{is_other} ? \@otherpars : \@pars}, $_ for @allpars;
    my @outputs = grep $_->{is_output}, @allpars;
    my @pdl_inits = grep !$_->{dimless}, @pars;
    my $compmode = grep $_->{use_comp}, @pdl_inits;
    pop @allpars if my $retcapture = $ret eq 'void' ? '' : ($ret =~ /^[A-Z]/ ? 'res' : '$res()');
    %hash = (%hash,
      Pars => join('; ', map $_->par, @pars), OtherPars => join('; ', map $_->par, @otherpars),
      PMCode => <<EOF,
sub ${main::PDLOBJ}::$func {
  my (@{[join ',', map "\$$_->{name}", grep !$_->{is_output}, @allpars]}) = \@_;
  @{[!@outputs ? '' : "my (@{[join ',', map qq{\$$_->{name}}, @outputs]});"]}
  @{[ join "\n  ", @defaults ]}
  ${main::PDLOBJ}::_${func}_int(@{[join ',', map '$'.$_->{name}, @pars, @otherpars]});
  @{[!@outputs ? '' : "!wantarray ? \$$outputs[-1]{name} : (@{[join ',', map qq{\$$_->{name}}, @outputs]})"]}
}
EOF
      Code => "void *vptmp;\ncw_error CW_err;\n",
    );
    my $doxy = doxyparse($doc);
    $doxy->{brief}[0] .= " NO BROADCASTING." if $compmode;
    $hash{Doc} = doxy2pdlpod($doxy);
    my $destroy_in = join '', map $_->destroy_code($compmode), grep !$_->{is_output}, @pdl_inits;
    my $destroy_out = join '', map $_->destroy_code($compmode), grep $_->{is_output}, @pdl_inits;
    my @nonfixed_outputs = grep $_->{is_output}, @pdl_inits;
    if ($compmode) {
      $hash{Comp} = join '; ', map +($_->{ctype} =~ /^[A-Z]/ ? $_->{ctype} : PDL::Type->new($_->{ctype})->ctype)." $_->{name}", @outputs;
      $hash{MakeComp} = join '',
        "cw_error CW_err;\n",
        (map "PDL_RETERROR(PDL_err, PDL->make_physical($_->{name}));\n", grep $_->{dimless}, @allpars),
        (map $_->{is_output} ? "$_->{blank};\n" : "@$_{qw(ctype name)}_LOCAL;\n".$_->frompdl(1,"$_->{name}_LOCAL"), @pdl_inits),
        (!@pdl_inits ? () : qq{if (@{[join ' || ', map "!".($_->{is_output}?"\$COMP($_->{name})":"$_->{name}_LOCAL"), @pdl_inits]}) {\n$destroy_in$destroy_out\$CROAK("Error during initialisation");\n}\n}),
        "CW_err = $cfunc(".join(',', ($retcapture ? '&$COMP(res)' : ()), map $_->c_input(1), @allpars).");\n",
        $destroy_in,
        "$IF_ERROR_RETURN;\n";
      $hash{CompFreeCodeComp} = $destroy_out;
      $hash{RedoDimsCode} = join '', "cw_error CW_err;\n", map $_->topdl1(1), @nonfixed_outputs;
      $hash{Code} .= join '', map $_->topdl2(1), @nonfixed_outputs;
      $hash{Code} .= "$retcapture = \$COMP(res);\n" if $retcapture;
    } else {
      $hash{Code} .= join '',
        (map "@$_{qw(ctype name)};\n".$_->frompdl(0,$_->{name}), @pdl_inits),
        (!@pdl_inits ? () : qq{if (@{[join ' || ', map "!$_->{name}", @pdl_inits]}) {\n$destroy_in$destroy_out\$CROAK("Error during initialisation");\n}\n}),
        "CW_err = $cfunc(".join(',', ($retcapture ? "&$retcapture" : ()), map $_->c_input, @allpars).");\n",
        (map $_->topdl2(0), @nonfixed_outputs),
        $destroy_in, $destroy_out,
        "$IF_ERROR_RETURN;\n";
    }
    pp_def($func, %hash);
}

sub genheader {
  my ($last, $classes) = @_;
  my $descrip_label = @$classes ? join(', ', @$classes) : $last;
  my $synopsis = join '', map "\n \$obj = PDL::OpenCV::$_->new;", @$classes;
  pp_addpm({At=>'Top'},<<"EOPM");
=head1 NAME
\nPDL::OpenCV::$last - PDL bindings for OpenCV $descrip_label
\n=head1 SYNOPSIS
\n use PDL::OpenCV::$last;$synopsis
\n=cut
\nuse strict;
use warnings;
EOPM
  pp_addhdr(qq{#include "opencv_wrapper.h"\n#include "wraplocal.h"\n});
  my @flist = genpp_readfile('funclist.pl');
  for my $c (@$classes) {
    pp_bless("PDL::OpenCV::$c");
    pp_addhdr(qq{typedef ${c}Wrapper *PDL__OpenCV__$c;\n});
    pp_addpm(<<EOD);
=head2 new
\n=for ref
\nInitialize OpenCV $c object.
\n=for example
\n  \$obj = PDL::OpenCV::$c->new;
\n=cut
EOD
    pp_addxs(<<EOF);
MODULE = ${main::PDLMOD} PACKAGE = PDL::OpenCV::$c PREFIX=cw_${c}_
\nPDL__OpenCV__$c cw_${c}_new(char *klass)
  CODE:\n    cw_error CW_err = cw_${c}_new(&RETVAL, klass);
    PDL->barf_if_error(*(pdl_error *)&CW_err);
  OUTPUT:\n    RETVAL
\nvoid cw_${c}_DESTROY(PDL__OpenCV__$c self)
EOF
    genpp(@$_) for grep $_->[0] eq $c, @flist;
  }
  pp_bless("PDL::OpenCV::$last");
  genpp(@$_) for grep $_->[0] eq '', @flist;
  genconsts("::$last");
}

sub genconsts {
  my ($last) = @_;
  return if !-f 'constlist.txt';
  open my $consts, '<', 'constlist.txt' or die "constlist.txt: $!";
  my %pkgsuff2defs;
  while (!eof $consts) {
    chomp(my $line = <$consts>);
    $line =~ s/^cv:://;
    my ($text, $args) = split /\|/, $line;
    pp_add_exported($text) if $text !~ /(.*)::/;
    my $pkgsuff = $1 || '';
    $pkgsuff2defs{$pkgsuff} ||= ['',''];
    $pkgsuff2defs{$pkgsuff}[1] .= "=item PDL::OpenCV$last\::$text(@{[$args || '']})\n\n";
    $text =~ s/::/_/g;
    $pkgsuff2defs{$pkgsuff}[0] .= "\nint cw_const_$text(@{[$args || '']})\n";
  }
  my $pod = "=head1 CONSTANTS\n\n=over\n\n";
  for my $key (sort keys %pkgsuff2defs) {
    my $pkg = join '::', grep length, "PDL::OpenCV$last", $key;
    my $pref = join '_', (grep length, "cw_const", $key), '';
    pp_addxs(<<EOF);
MODULE = ${main::PDLMOD} PACKAGE = $pkg PREFIX=$pref
$pkgsuff2defs{$key}[0]
EOF
    $pod .= $pkgsuff2defs{$key}[1];
  }
  pp_addpm("$pod\n=back\n\n=cut\n\n");
}

sub genpp_readfile {
  my ($file) = @_;
  my @flist = do ''. catfile curdir, $file;
  die if $@;
  @flist;
}

1;

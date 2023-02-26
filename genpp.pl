use strict;
use warnings;
use PDL::Types;
use File::Spec::Functions qw(catfile curdir);
use File::Basename 'dirname';
require ''. catfile dirname(__FILE__), 'doxyparse.pl';

my $T = [qw(A B S U L F D)];
our %type_overrides = (
  String => ['StringWrapper*', 'StringWrapper*'], # PP, C
  bool => ['byte', 'unsigned char'],
);
our %type_alias = (
  char => 'bool',
  string => 'String',
);
$type_overrides{$_} = $type_overrides{$type_alias{$_}} for keys %type_alias;
our %default_overrides = (
  'vector_Mat()' => ['undef',],
  'Mat()' => ['PDL->zeroes(sbyte,0,0,0)',],
  'Point()' => ['PDL->zeroes(sbyte,2)',],
  false => [0,0], # perl, C
  true => [1,1],
);
our %extra_cons_args = (
  LineSegmentDetector => [[qw(int lsd_type)]],
  String => [['const char*', 'str']],
);
our $IF_ERROR_RETURN = "if (CW_err.error) return *(pdl_error *)&CW_err";

{
package PP::OpenCV;
our %DIMTYPES = (
  Point2f=>[[qw(float x)], [qw(float y)]],
  Point2d=>[[qw(double x)], [qw(double y)]],
  Point=>[[qw(ptrdiff_t x)], [qw(ptrdiff_t y)]],
  Rect=>[[qw(ptrdiff_t x)], [qw(ptrdiff_t y)], [qw(ptrdiff_t width)], [qw(ptrdiff_t height)]],
  Scalar=>[[qw(double v0 val[0])], [qw(double v1 val[1])], [qw(double v2 val[2])], [qw(double v3 val[3])]],
  Size=>[[qw(ptrdiff_t width)], [qw(ptrdiff_t height)]],
);
our %CTYPE2PDL = map +($_->realctype => $_->ppforcetype), PDL::Types::types();
sub new {
  my ($class, $pcount, $type, $name, $default, $f) = @_;
  my %flags = map +($_=>1), @{$f||[]};
  my $self = bless {type=>$type, name=>$name, is_io=>$flags{'/IO'}, is_output=>$flags{'/O'}, pcount => $pcount, pdltype => ''}, $class;
  $self->{is_vector} = (my $nonvector_type = $type) =~ s/vector_//g;
  $nonvector_type = $type_alias{$nonvector_type} || $nonvector_type;
  $self->{type_pp} = ($type_overrides{$nonvector_type} || [$nonvector_type])->[0];
  $self->{type_c} = ($type_overrides{$nonvector_type} || [0,$nonvector_type])->[1];
  $self->{default} = $default if defined $default and length $default;
  @$self{qw(is_other naive_otherpar use_comp)} = (1,1,1), return $self if $self->{type_c} eq 'StringWrapper*' and !$self->{is_vector};
  if ($self->{is_vector}) {
    $self->{fixeddims} = 1 if my $spec = $DIMTYPES{$nonvector_type};
    $self->{use_comp} = 1 if $self->{is_output};
    @$self{qw(pdltype type_c)} = ($spec ? $CTYPE2PDL{$spec->[0][0]} : $nonvector_type, ('vector_'x$self->{is_vector})."${nonvector_type}Wrapper *",
    );
    @$self{qw(is_other naive_otherpar use_comp pdltype)} = (1,1,1,'') if $self->{type_pp} eq 'Mat' or $self->{type_pp} eq 'StringWrapper*';
    return $self;
  } elsif ($self->{type_pp} !~ /^[A-Z]/) {
    (my $pdltype = $self->{type_pp}) =~ s#\s*\*+$##;
    @$self{qw(dimless pdltype was_ptr)} = (1, $pdltype, $type ne $pdltype);
    return $self;
  }
  @$self{qw(was_ptr type)} = (1, $type) if $type =~ s/\s*\*+$//;
  %$self = (%$self,
    type_c => "${type}Wrapper *",
    fixeddims => 0,
  );
  if (my $spec = $DIMTYPES{$type}) {
    $self->{fixeddims} = 1;
    $self->{pdltype} = $CTYPE2PDL{$spec->[0][0]};
  } elsif ($type ne 'Mat') {
    @$self{qw(is_other use_comp)} = (1,1);
  }
  $self->{use_comp} = 1 if $self->{is_output} and !$self->{fixeddims};
  bless $self, $class;
}
sub c_input {
  my ($self, $compmode) = @_;
  return ($self->{type} =~ /\*$/ ? '&' : '').
    ($compmode ? "(($self->{type_c}*)($self->{name}->data))[0]" : "\$$self->{name}()")
    if $self->{dimless};
  return "\$COMP($self->{name})" if $self->{use_comp};
  $self->{name}.($compmode?'_LOCAL':'');
}
sub par {
  my ($self, $phys) = @_;
  my $flags = $self->{is_output} ? 'o' : $self->{is_io} ? 'io' : '';
  $flags = join ',', grep length, $flags, $phys ? 'phys' : ();
  join ' ', grep length, $self->{pdltype},
    ($flags ? "[$flags]" : ()),
    $self->_par;
}
sub _par {
  my ($self) = @_;
  return "$self->{name}()" if $self->{dimless};
  return "@$self{qw(type_c name)}" if $self->{naive_otherpar};
  my ($name, $type, $pcount) = @$self{qw(name type pcount)};
  return "$name(l$pcount,c$pcount,r$pcount)" if $type eq 'Mat';
  return "$name(n$pcount=".scalar(@{$DIMTYPES{$type}}).")" if $self->{fixeddims} and !$self->{is_vector};
  my $i = 0;
  return "$name(".join(',',
    (!$self->{fixeddims} ? () : "n$pcount=".scalar(@{$DIMTYPES{$self->{type_pp}}})),
    (map "n${pcount}d".$i++, 1..$self->{is_vector}), ).")"
    if $self->{is_vector};
  "PDL__OpenCV__$type $name";
}
sub frompdl {
  my ($self, $compmode) = @_;
  die "Called frompdl on OtherPar" if $self->{is_other};
  my ($name, $type, $pcount) = @$self{qw(name type pcount)};
  return "CW_err = cw_${type}_new(&\$COMP($name), NULL); $IF_ERROR_RETURN;\n" if $compmode and $self->{is_output};
  my $localname = $self->c_input($compmode);
  my $decl = ($compmode && ($self->{use_comp} || $self->{is_other})) ? '' : "$self->{type_c} $localname;\n";
  return $decl.qq{CW_err = cw_${type}_newWithVals(@{[
    join ',', "&$localname",
        $compmode ? "(($self->{type_c} *)$name->data),$name->dims[0]" : "\$P($name),\$SIZE(n${pcount}d0)"
      ]})}."; $IF_ERROR_RETURN;\n" if $self->{is_vector};
  return $decl."CW_err = cw_Mat_newWithDims(" .
    ($compmode
      ? join ',', "&$localname", (map "$name->dims[$_]", 0..2), "$name->datatype,$name->data"
      : "&$localname,\$SIZE(l$pcount),\$SIZE(c$pcount),\$SIZE(r$pcount),\$PDL($name)->datatype,\$P($name)"
    ) .
    "); $IF_ERROR_RETURN;\n" if !$self->{fixeddims};
  $decl.qq{CW_err = cw_${type}_newWithVals(@{[
      join ',', "&$localname", map $compmode ? "(($DIMTYPES{$type}[0][0] *)$name->data)[$_]" : "\$$name(n$pcount=>$_)",
        0..@{$DIMTYPES{$type}}-1
    ]})}."; $IF_ERROR_RETURN;\n";
}
sub topdl1 {
  my ($self, $compmode) = @_;
  die "Called topdl1 on OtherPar" if $self->{is_other};
  my ($name, $type, $pcount) = @$self{qw(name type pcount)};
  return
    "PDL_Indx ${name}_count;\nCW_err = cw_${type}_size(&\$SIZE(n${pcount}d0), ".$self->c_input($compmode)."); $IF_ERROR_RETURN;\n"
    if $self->{is_vector};
  return
    "CW_err = cw_Mat_pdlDims(".$self->c_input($compmode).", &\$PDL($name)->datatype, &\$SIZE(l$pcount), &\$SIZE(c$pcount), &\$SIZE(r$pcount)); $IF_ERROR_RETURN;\n"
    if !$self->{fixeddims};
  "";
}
sub topdl2 {
  my ($self, $compmode) = @_;
  die "Called topdl2 on OtherPar" if $self->{is_other};
  my ($name, $type, $pcount) = @$self{qw(name type pcount)};
  return <<EOF if $self->{is_vector} or !$self->{fixeddims};
CW_err = cw_${type}_copyDataTo(@{[$self->c_input($compmode)]}, \$P($name), \$PDL($name)->nbytes);
$IF_ERROR_RETURN;
EOF
  qq{CW_err = cw_${type}_getVals(}.$self->c_input($compmode).qq{,@{[join ',', map "&\$$name(n$pcount=>$_)", 0..@{$DIMTYPES{$type}}-1]}); $IF_ERROR_RETURN;\n};
}
sub destroy_code {
  my ($self, $compmode) = @_;
  "cw_$self->{type}_DESTROY(".$self->c_input($compmode).");\n";
}
sub default_pl {
  my ($self) = @_;
  my $d = $self->{default} // '';
  $d =~ s/[A-Z][A-Z0-9_]+/$&()/g if length $d and $d !~ /\(/;
  if ($self->{is_output}) {
    $d = 'PDL->null' if !$self->{naive_otherpar} and (!length $d or $d eq 'Mat()' or ($d eq '0' && $self->{was_ptr}));
  }
  if ($default_overrides{$d}) {
    $d = $default_overrides{$d}[0];
  }
  length $d ? "\$$self->{name} = $d if !defined \$$self->{name};" : ();
}
sub xs_par {
  my ($self) = @_;
  my $xs_par = ($self->{type} =~ /^[A-Z]/ && $self->{is_other}) ? $self->par : "@$self{qw(type name)}";
  my $d = $self->{default} // '';
  $d = $default_overrides{$d}[1] if $default_overrides{$d};
  $d = 'cw_const_' . $d . '()' if length $d and $d !~ /\(/ and $d =~ /[^0-9\.\-]/;
  $xs_par . (length $d ? "=$d" : '');
}
sub cdecl {
  my ($self) = @_;
  ($self->{use_comp} ? $self->{type_c} : PDL::Type->new($self->{type_pp})->ctype)." $self->{name}";
}
}

sub text_trim {
  my ($text) = @_;
  $text =~ s/\s+$/\n/gm;
  $text =~ s/\n{3,}/\n\n/g;
  $text;
}

sub make_example {
  my ($func, $ismethod, $inputs, $outputs) = @_;
  $inputs = [@$inputs[1..$#$inputs]] if $ismethod;
  "\n\n=for example\n\n ".
    (!@$outputs ? '' : "(@{[join ',', map qq{\$$_->{name}}, @$outputs]}) = ").
    ($ismethod ? '$obj->' : '')."$func".
    (@$inputs ? '('.join(',', map "\$$_->{name}", @$inputs).')' : '').
    ";\n\n";
}

sub genpp {
    my ($class,$func,$doc,$ismethod,$ret,@params) = @_;
    die "No class given for method='$ismethod'" if !$class and $ismethod;
    my %hash = (NoPthread=>1, HandleBad=>0);
    my $doxy = doxyparse($doc);
    my $pcount = 1;
    my $cfunc = join('_', 'cw', my $pfunc = join '_', grep length,$class,$func);
    unshift @params, [$class,'self'] if $ismethod;
    push @params, [$ret,'res','',['/O']] if $ret ne 'void';
    my @allpars = map PP::OpenCV->new($pcount++, @$_), @params;
    my (@inputs, @outputs); push @{$_->{is_output} ? \@outputs : \@inputs}, $_ for @allpars;
    $hash{PMFunc} = $ismethod ? '' : "*$func = \\&${main::PDLOBJ}::$func;\n";
    if (!grep $_->{is_vector} || ($_->{type_pp} =~ /^[A-Z]/ && !$_->{is_other}), @allpars) {
      $doxy->{brief}[0] .= make_example($func, $ismethod, \@inputs, \@outputs);
      $hash{Doc} = text_trim doxy2pdlpod($doxy);
      pp_addpm("=head2 $func\n\n$hash{Doc}\n\n=cut\n\n");
      pp_addpm($hash{PMFunc}), pp_add_exported($func) if !$ismethod;
      my $ret_type = $ret eq 'void' ? $ret : pop(@allpars)->{type_c};
      my @cw_params = (($ret ne 'void' ? '&RETVAL' : ()), map $_->{name}, @allpars);
      my $xs = <<EOF;
MODULE = ${main::PDLMOD} PACKAGE = ${main::PDLOBJ} PREFIX=@{[join '_', grep length,'cw',$class]}_
\n$ret_type $cfunc(@{[join ', ', map $_->xs_par, @allpars]})
  PROTOTYPE: DISABLE
  CODE:
    cw_error CW_err = $cfunc(@{[join ', ', @cw_params]});
    PDL->barf_if_error(*(pdl_error *)&CW_err);
EOF
      $xs .= "  OUTPUT:\n    RETVAL\n" if $ret_type ne 'void';
      pp_addxs($xs);
      return;
    }
    my @defaults = map $_->default_pl, @allpars;
    my (@pars, @otherpars); push @{$_->{is_other} ? \@otherpars : \@pars}, $_ for @allpars;
    my @pdl_inits = grep !$_->{dimless}, @pars;
    my $compmode = grep $_->{use_comp}, @pdl_inits;
    (my $ret_obj) = pop @allpars if my $retcapture = $ret eq 'void' ? '' : ($ret =~ /^[A-Z]/ ? 'res' : '$res()');
    %hash = (%hash,
      Pars => join('; ', map $_->par(1), @pars), OtherPars => join('; ', map $_->par, @otherpars),
      GenericTypes=>(grep !$_->{pdltype}, @pars) ? $T : ['D'],
      PMCode => <<EOF,
sub ${main::PDLOBJ}::$func {
  barf "Usage: ${main::PDLOBJ}::$func(@{[join ',', map "\\\$$_->{name}", @inputs]})\n" if \@_ < @{[0+(grep !defined $_->{default} || !length $_->{default}, @inputs)]};
  my (@{[join ',', map "\$$_->{name}", @inputs]}) = \@_;
  @{[!@outputs ? '' : "my (@{[join ',', map qq{\$$_->{name}}, @outputs]});"]}
  @{[ join "\n  ", @defaults ]}
  ${main::PDLOBJ}::_${pfunc}_int(@{[join ',', map '$'.$_->{name}, @pars, @otherpars]});
  @{[!@outputs ? '' : "!wantarray ? \$$outputs[-1]{name} : (@{[join ',', map qq{\$$_->{name}}, @outputs]})"]}
}
EOF
      Code => "cw_error CW_err;\n",
    );
    $doxy->{brief}[0] .= " NO BROADCASTING." if $compmode;
    $doxy->{brief}[0] .= make_example($func, $ismethod, \@inputs, \@outputs);
    $hash{Doc} = text_trim doxy2pdlpod($doxy);
    my $destroy_in = join '', map $_->destroy_code($compmode), grep !$_->{is_output}, @pdl_inits;
    my $destroy_out = join '', map $_->destroy_code($compmode), grep $_->{is_output}, @pdl_inits;
    my @nonfixed_outputs = grep $_->{is_output}, @pdl_inits;
    if ($compmode) {
      $hash{Comp} = join '; ', map $_->cdecl, grep !$_->{is_other}, @outputs;
      $hash{MakeComp} = join '',
        "cw_error CW_err;\n",
        (map "PDL_RETERROR(PDL_err, PDL->make_physical($_->{name}));\n", @pars),
        (map $_->frompdl(1), @pdl_inits),
        (!@pdl_inits ? () : qq{if (@{[join ' || ', map "!".$_->c_input(1), @pdl_inits]}) {\n$destroy_in$destroy_out\$CROAK("Error during initialisation");\n}\n}),
        "CW_err = $cfunc(".join(',', ($retcapture ? '&$COMP(res)' : ()), map $_->c_input(1), @allpars).");\n",
        $destroy_in,
        "$IF_ERROR_RETURN;\n";
      $hash{CompFreeCodeComp} = $destroy_out;
      $hash{RedoDimsCode} = join '', "cw_error CW_err;\n", map $_->topdl1(1), @nonfixed_outputs;
      $hash{Code} .= join '', map $_->topdl2(1), @nonfixed_outputs;
      $hash{Code} .= "$retcapture = \$COMP(res);\n" if $ret_obj and !$ret_obj->{use_comp} and $ret !~ /^[A-Z]/;
    } else {
      $hash{Code} .= join '',
        (map $_->frompdl(0), @pdl_inits),
        (!@pdl_inits ? () : qq{if (@{[join ' || ', map "!$_->{name}", @pdl_inits]}) {\n$destroy_in$destroy_out\$CROAK("Error during initialisation");\n}\n}),
        "CW_err = $cfunc(".join(',', ($retcapture ? "&".$ret_obj->c_input(0) : ()), map $_->c_input, @allpars).");\n",
        (map $_->topdl2(0), @nonfixed_outputs),
        $destroy_in, $destroy_out,
        "$IF_ERROR_RETURN;\n";
    }
    pp_def($pfunc, %hash);
}

sub genheader {
  my ($last) = @_;
  local $@; my @classdata = !-f 'classes.pl' ? () : do ''. catfile curdir, 'classes.pl'; die if $@;
  my %class2doc = map +($_->[0]=>$_->[1]), @classdata;
  my @classes = sort keys %class2doc;
  my $descrip_label = @classes ? join(', ', @classes) : $last;
  my $synopsis = join '', map "\n \$obj = PDL::OpenCV::$_->new@{[
    @{$extra_cons_args{$_} || []} ? '('.join(', ', map qq{\$$_->[1]}, @{$extra_cons_args{$_} || []}).')' : ''
  ]};", @classes;
  pp_addpm({At=>'Top'},<<"EOPM");
=head1 NAME
\nPDL::OpenCV::$last - PDL bindings for OpenCV $descrip_label
\n=head1 SYNOPSIS
\n use PDL::OpenCV::$last;$synopsis
\n=cut
\nuse strict;
use warnings;
use PDL::OpenCV; # get constants
EOPM
  pp_addhdr(qq{#include "opencv_wrapper.h"\n#include "wraplocal.h"\n});
  my @flist = genpp_readfile('funclist.pl');
  my @topfuncs = grep $_->[0] eq '', @flist;
  if (@topfuncs) {
    pp_bless("PDL::OpenCV::$last");
    pp_addxs(<<EOF); # work around PP bug
MODULE = ${main::PDLMOD} PACKAGE = ${main::PDLOBJ}
EOF
    genpp(@$_) for @topfuncs;
  } else {
    pp_addpm("=pod\n\nNone.\n\n=cut\n\n");
  }
  for my $c (@classes) {
    pp_bless("PDL::OpenCV::$c");
    pp_addhdr(qq{typedef ${c}Wrapper *PDL__OpenCV__$c;\n});
    my $doc = $class2doc{$c} // '';
    $doc =~ s/\@brief\s*//;
    pp_addpm(<<EOD);
=head1 METHODS for PDL::OpenCV::$c\n\n
$doc\n\n
=head2 new
\n=for ref
\nInitialize OpenCV $c object.
\n=for example
\n  \$obj = PDL::OpenCV::$c->new@{[
  @{$extra_cons_args{$c} || []} ? '('.join(', ', map qq{\$$_->[1]}, @{$extra_cons_args{$c} || []}).')' : ''
]};
\n=cut
EOD
    pp_addxs(<<EOF);
MODULE = ${main::PDLMOD} PACKAGE = PDL::OpenCV::$c PREFIX=cw_${c}_
\nPDL__OpenCV__$c cw_${c}_new(char *klass@{[
  map ", @$_", @{$extra_cons_args{$c} || []}
]})
  CODE:\n    cw_error CW_err = cw_${c}_new(&RETVAL, klass@{[
  map ", $_->[1]", @{$extra_cons_args{$c} || []}
]});
    PDL->barf_if_error(*(pdl_error *)&CW_err);
  OUTPUT:\n    RETVAL
\nvoid cw_${c}_DESTROY(PDL__OpenCV__$c self)
EOF
    genpp(@$_) for grep $_->[0] eq $c, @flist;
  }
  pp_export_nothing();
  pp_add_exported(map $_->[1], grep !$_->[3], @flist);
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

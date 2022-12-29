use strict;
use warnings;
use PDL::Types;
use File::Spec::Functions qw(catfile curdir);

my $T = [qw(A B S U L F D)];
our %type_overrides = (
  String => ['char *', 'char *'], # PP, C
  bool => ['byte', 'unsigned char'],
);

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
  my ($class, $type, $name, $pcount) = @_;
  my $self = bless {type=>$type, name=>$name}, $class;
  @$self{qw(is_other naive_otherpar)} = (1,1), return $self if $type eq 'char *';
  if ($type !~ /^[A-Z]/) {
    (my $pdltype = $type) =~ s#\s*\*$##;
    @$self{qw(simple_pdl pdltype ctype)} = (1, $pdltype, $type);
    return $self;
  }
  %$self = (%$self,
    pcount => $pcount,
    ctype => "${type}Wrapper *",
    pdltype => '',
    fixeddims => 0,
    destroy => "cw_${type}_DESTROY",
    blank => "cw_${type}_new(NULL)",
  );
  if (my $spec = $DIMTYPES{$type}) {
    $self->{fixeddims} = 1;
    $self->{pdltype} = $spec->[0][0] eq 'ptrdiff_t' ? "indx" : $spec->[0][0];
  } elsif ($type ne 'Mat') {
    $self->{is_other} = 1;
  }
  bless $self, $class;
}
sub c_input {
  my ($self) = @_;
  return $self->{name} if !$self->{simple_pdl};
  [($self->{type} =~ /\*$/ ? '&' : ''), @$self{qw(name pdltype)}];
}
sub par {
  my ($self) = @_;
  return "$self->{name}()" if $self->{simple_pdl};
  return "@$self{qw(type name)}" if $self->{naive_otherpar};
  my ($name, $type, $pcount) = @$self{qw(name type pcount)};
  return "$name(l$pcount,c$pcount,r$pcount)" if $type eq 'Mat';
  return "$name(n${type}$pcount=".scalar(@{$DIMTYPES{$type}}).")" if $self->{fixeddims};
  "PDL__OpenCV__$type $name";
}
sub frompdl {
  my ($self, $iscomp) = @_;
  my ($name, $type, $pcount) = @$self{qw(name type pcount)};
  return undef if $self->{is_other};
  return "cw_Mat_newWithDims(" .
    ($iscomp
      ? join ',', (map "$name->dims[$_]", 0..2), "$name->datatype,$name->data"
      : "\$SIZE(l$pcount),\$SIZE(c$pcount),\$SIZE(r$pcount),\$PDL($name)->datatype,\$P($name)"
    ) .
    ")" if !$self->{fixeddims};
  qq{cw_${type}_newWithVals(@{[
      join ',', map $iscomp ? "(($DIMTYPES{$type}[0][0] *)$name->data)[$_]" : "\$$name(n${type}$pcount=>$_)",
        0..@{$DIMTYPES{$type}}-1
    ]})};
}
sub topdl1 {
  my ($self, $iscomp) = @_;
  my ($name, $type, $pcount) = @$self{qw(name type pcount)};
  return undef if $self->{is_other};
  return
    "cw_Mat_pdlDims(".($iscomp ? "\$COMP($name)" : $name).", &\$PDL($name)->datatype, &\$SIZE(l$pcount), &\$SIZE(c$pcount), &\$SIZE(r$pcount))"
    if !$self->{fixeddims};
  "";
}
sub topdl2 {
  my ($self, $iscomp) = @_;
  my ($name, $type, $pcount) = @$self{qw(name type pcount)};
  return undef if $self->{is_other};
  return
    "memmove(\$P($name), cw_Mat_ptr(".($iscomp ? "\$COMP($name)" : $name)."), \$PDL($name)->nbytes)"
    if !$self->{fixeddims};
  qq{cw_${type}_getVals(}.($iscomp ? "\$COMP($name)" : $name).qq{,@{[join ',', map "&\$$name(n${type}$pcount=>$_)", 0..@{$DIMTYPES{$type}}-1]})};
}
sub destroy_code {
  my ($self, $iscomp, $isin) = @_;
  return "$self->{destroy}($self->{name});\n" if !$iscomp;
  "$self->{destroy}(".($isin ? "$self->{name}_LOCAL" : "\$COMP($self->{name})").");\n";
}
}

sub genpp {
    my ($class,$func,$doc,$ismethod,$ret,@params) = @_;
    die "No class given for method='$ismethod'" if !$class and $ismethod;
    $_ = '' for my ($callprefix, $compmode);
    my %hash = (GenericTypes=>$T, NoPthread=>1, HandleBad=>0, Doc=>"=for ref\n\n$doc");
    $hash{PMFunc} = '' if $ismethod;
    my $pcount = 1;
    my $cfunc = join('_', grep length,'cw',$class,$func);
    unshift @params, [$class,'self'] if $ismethod;
    if (!grep /^[A-Z]/ && !PP::OpenCV->new($_, '', 0)->{is_other}, map $_->[0], @params, $ret ne 'void' ? [$type_overrides{$ret} ? $type_overrides{$ret}[0] : $ret] : ()) {
      $ret = $type_overrides{$ret}[1] if $type_overrides{$ret};
      pp_addpm("=head2 $func\n\n$hash{Doc}\n\n=cut\n\n");
      pp_addpm("*$func = \\&${main::PDLOBJ}::$func;\n") if !$ismethod;
      pp_add_exported($func);
      my @xs_params;
      for (@params) {
        my ($type, $var) = @$_;
        $type = $type_overrides{$type}[1] if $type_overrides{$type};
        my ($is_other, $par) = 0;
        if ($type =~ /^[A-Z]/) {
          my $obj = PP::OpenCV->new($type, $var, 0);
          ($is_other, $type, $par) = (@$obj{qw(is_other type)}, $obj->par);
        }
        push @xs_params, $is_other ? $par : "$type $var";
      }
      pp_addxs(<<EOF);
MODULE = ${main::PDLMOD} PACKAGE = ${main::PDLOBJ} PREFIX=@{[join '_', grep length,'cw',$class]}_
\n$ret $cfunc(@{[join ', ', @xs_params]})
  PROTOTYPE: DISABLE
EOF
      return;
    }
    $ret = $type_overrides{$ret}[0] if $type_overrides{$ret};
    push @params, [$ret,'res','',['/O']] if $ret ne 'void';
    my (@c_input, @pp_input, @pars, @otherpars, @pdl_inits, @outputs, @pmpars, @defaults, %var2count, %var2usecomp);
    for (@params) {
      my ($type, $var, $default, $f) = @$_;
      $type = $type_overrides{$type}[0] if $type_overrides{$type};
      $default //= '';
      my %flags = map +($_=>1), @{$f||[]};
      my $obj = PP::OpenCV->new($type, $var, $pcount);
      (my ($par, $pdltype), $type) = ($obj->par, @$obj{qw(pdltype ctype)});
      push @c_input, $obj->c_input;
      if ($obj->{is_other}) {
        die "Error: OtherPars '$var' is output" if $flags{'/O'};
        push @otherpars, [$par, $var];
        $var2usecomp{$var} = 1;
      } else {
        push @pp_input, $var;
        push @pars, join ' ', grep length, $pdltype, ($flags{'/O'} ? '[o]' : ()), $par;
        if (!$obj->{simple_pdl}) {
          push @pdl_inits, [$var, $flags{'/O'}, $type, $pcount, $obj, @$obj{qw(blank)}, sub {$obj->frompdl(@_)}];
          $compmode = $var2usecomp{$var} = 1 if $flags{'/O'} and !$obj->{fixeddims};
          $var2count{$var} = $pcount++;
        }
      }
      if ($flags{'/O'}) {
        push @outputs, [$type, $var, sub {$obj->topdl1(@_)}, sub {$obj->topdl2(@_)}];
        $default = 'PDL->null' if !length $default;
      } else {
        push @pmpars, $var;
      }
      push @defaults, "\$$var = $default if !defined \$$var;" if length $default;
    }
    push @pp_input, map $_->[1], @otherpars;
    $callprefix = ($ret =~ /^[A-Z]/ ? 'res' : '$res()').' = ', pop @c_input if $ret ne 'void';
    %hash = (%hash,
      Pars => join('; ', @pars), OtherPars => join('; ', map $_->[0], @otherpars),
      PMCode => <<EOF,
sub ${main::PDLOBJ}::$func {
  my (@{[join ',', map "\$$_", @pmpars]}) = \@_;
  @{[!@outputs ? '' : "my (@{[join ',', map qq{\$$_->[1]}, @outputs]});"]}
  @{[ join "\n  ", @defaults ]}
  ${main::PDLOBJ}::_${func}_int(@{[join ',', map "\$$_", @pp_input]});
  @{[!@outputs ? '' : "!wantarray ? \$$outputs[-1][1] : (@{[join ',', map qq{\$$_->[1]}, @outputs]})"]}
}
EOF
    );
    my $destroy_in = join '', map $_->[4]->destroy_code($compmode,1), grep !$_->[1], @pdl_inits;
    my $destroy_out = join '', map $_->[4]->destroy_code($compmode,0), grep $_->[1], @pdl_inits;
    if ($compmode) {
      $hash{Comp} = join '; ', map +($_->[0] =~ /^[A-Z]/ ? $_->[0] : PDL::Type->new($_->[0])->ctype)." $_->[1]", @outputs;
      $hash{MakeComp} = join '',
        (map "PDL_RETERROR(PDL_err, PDL->make_physical($_->[1]));\n", grep ref, @c_input),
        (map $_->[1] ? "\$COMP($_->[0]) = $_->[5];\n" : "@$_[2,0]_LOCAL = ".$_->[6]->(1).";\n", @pdl_inits),
        (!@pdl_inits ? () : qq{if (@{[join ' || ', map "!".($_->[1]?"\$COMP($_->[0])":"$_->[0]_LOCAL"), @pdl_inits]}) {\n$destroy_in$destroy_out\$CROAK("Error during initialisation");\n}\n}),
        ($callprefix && '$COMP(res) = ').$cfunc."(".join(',', map ref()?"$_->[0](($_->[2]*)($_->[1]->data))[0]":$var2usecomp{$_}?"\$COMP($_)":$_.'_LOCAL', @c_input).");\n",
        $destroy_in;
      $hash{CompFreeCodeComp} = $destroy_out;
      my @map_tuples = map [$_->[1], $var2count{$_->[1]}, map $_->(1), @$_[2,3]], grep $var2count{$_->[1]}, @outputs;
      $hash{RedoDimsCode} = join '', map "$_->[2];\n", @map_tuples;
      $hash{Code} = join '', map "$_->[3];\n", @map_tuples;
      $hash{Code} .= $callprefix.'$COMP(res);'."\n" if $callprefix;
    } else {
      my @map_tuples = map [$_->[1], $var2count{$_->[1]}, map $_->(0), @$_[2,3]], grep $var2count{$_->[1]}, @outputs;
      $hash{Code} = join '',
        (map "@$_[2,0] = ".$_->[6]->(0).";\n", @pdl_inits),
        (!@pdl_inits ? () : qq{if (@{[join ' || ', map "!$_->[0]", @pdl_inits]}) {\n$destroy_in$destroy_out\$CROAK("Error during initialisation");\n}\n}),
        $callprefix.$cfunc."(".join(',', map ref()?"$_->[0]\$$_->[1]()":$var2usecomp{$_}?"\$COMP($_)":$_, @c_input).");\n",
        (map "$_->[3];\n", @map_tuples),
        $destroy_in, $destroy_out;
    }
    pp_def($func, %hash);
}

sub add_const {
  my ($pkg, $args, $text) = @_;
  pp_add_exported($text);
  pp_addxs(<<EOF);
MODULE = ${main::PDLMOD} PACKAGE = $pkg PREFIX=cw_const_
\nint cw_const_$text(@{[@$args ? join(',',map qq{@$_}, @$args) : '']})
EOF
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
  while (!eof $consts) {
    chomp(my $line = <$consts>);
    add_const("PDL::OpenCV$last", [], $line);
  }
}

sub genpp_readfile {
  my ($file) = @_;
  my @flist = do ''. catfile curdir, $file;
  die if $@;
  @flist;
}

1;

use strict;
use warnings;
use PDL::Types;

my $T = [qw(A B S U L F D)];

sub genpp_par {
  my ($type, $name, $pcount) = @_;
  my ($is_other, $ctype, $par, $destroy, $blank, $frompdl, $topdl1, $topdl2) = (
    0, "${type}Wrapper *", undef,
    "cw_${type}_DESTROY", "cw_${type}_new(NULL)",
  );
  if ($type eq 'Mat') {
    $par = "$name(l$pcount,c$pcount,r$pcount)";
    $frompdl = sub {
      my ($iscomp) = @_;
      "cw_Mat_newWithDims(" .
        ($iscomp
          ? join ',', (map "$name->dims[$_]", 0..2), "$name->datatype,$name->data"
          : "\$SIZE(l$pcount),\$SIZE(c$pcount),\$SIZE(r$pcount),\$PDL($name)->datatype,\$P($name)"
        ) .
        ")"
    };
    $topdl1 = "cw_Mat_pdlDims(\$COMP($name), &\$PDL($name)->datatype, &\$SIZE(l$pcount), &\$SIZE(c$pcount), &\$SIZE(r$pcount))";
    $topdl2 = "memmove(\$P($name), cw_Mat_ptr(\$COMP($name)), \$PDL($name)->nbytes)";
  } elsif ($type eq 'Size') {
    $par = "indx $name(sizen=2)";
    $frompdl = sub {
      my ($iscomp) = @_;
      "cw_Size_newWithDims(\$$name(sizen=>0), \$$name(sizen=>1))"
    };
  } else {
    $par = "PDL__OpenCV__$type $name";
    $is_other = 1;
  }
  ($is_other, $par, $ctype, $destroy, $blank, $frompdl, $topdl1, $topdl2);
}

sub genpp {
    my ($class,$func,$doc,$ismethod,$ret,$opt,@params) = @_;
    die "No class given for method='$ismethod'" if !$class and $ismethod;
    $_ = '' for my ($callprefix, $compmode);
    my %hash = (GenericTypes=>$T, NoPthread=>1, HandleBad=>0, Doc=>"=for ref\n\n$doc");
    my $pcount = 1;
    my $cfunc = join('_', grep length,'cw',$class,$func);
    unshift @params, [$class,'self'] if $ismethod;
    if (!grep /^[A-Z]/ && !(genpp_par $_, '', 0)[0], map $_->[0], @params) {
      pp_addpm("=head2 $func\n\n$hash{Doc}\n");
      pp_add_exported($func);
      my @xs_params;
      for (@params) {
        my ($type, $var) = @$_;
        my ($is_other, $par) = 0;
        if ($type =~ /^[A-Z]/) {
          ($is_other, $par, $type) = genpp_par($type, $var, 0);
        }
        push @xs_params, $is_other ? $par : "$type $var";
      }
      pp_addxs(<<EOF);
MODULE = ${main::PDLOBJ} PACKAGE = ${main::PDLOBJ} PREFIX=@{[join '_', grep length,'cw',$class]}_
\n$ret $cfunc(@{[join ', ', @xs_params]})
  PROTOTYPE: DISABLE
EOF
      return;
    }
    push @params, [$ret,'res','',['/O']] if $ret ne 'void';
    my (@c_input, @pp_input, @pars, @otherpars, @pdl_inits, @outputs, @pmpars, @defaults, %var2count, %var2usecomp);
    for (@params) {
      my ($type, $var, $default, $f) = @$_;
      $default //= '';
      my %flags = map +($_=>1), @{$f||[]};
      my ($partype, $par, $is_other, $destroy, $blank, $frompdl, $topdl1, $topdl2) = '';
      if ($type =~ /^[A-Z]/) {
        ($is_other, $par, $type, $destroy, $blank, $frompdl, $topdl1, $topdl2) = genpp_par($type, $var, $pcount);
        if ($is_other) {
          die "Error: OtherPars '$var' is output" if $flags{'/O'};
          push @otherpars, [$par, $var];
          $var2usecomp{$var} = 1;
        } else {
          push @pdl_inits, [$var, $flags{'/O'}, $type, $pcount, $destroy, $blank, $frompdl, $topdl1, $topdl2];
          $compmode = $var2usecomp{$var} = 1 if $flags{'/O'};
          $var2count{$var} = $pcount++;
        }
        push @c_input, $var;
      } elsif ($type eq 'char *') {
        $is_other = 1;
        push @otherpars, ["$type $var", $var];
        $var2usecomp{$var} = 1;
        push @c_input, $var;
      } else {
        ($partype = $type) =~ s#\s*\*$##;
        $par = "$var()";
        push @c_input, [($type =~ /\*$/ ? '&' : ''), $var, $partype];
      }
      if ($flags{'/O'}) {
        push @outputs, [$type, $var, $topdl1, $topdl2];
        $default = 'PDL->null' if !length $default;
      } else {
        push @pmpars, $var;
      }
      push @defaults, "\$$var = $default if !defined \$$var;" if length $default;
      if (!$is_other) {
        push @pp_input, $var;
        push @pars, join ' ', grep length, $partype, ($flags{'/O'} ? '[o]' : ()), $par;
      }
    }
    push @pp_input, map $_->[1], @otherpars;
    $callprefix = '$res() = ', pop @c_input if $ret ne 'void';
    %hash = (%hash,
      Pars => join('; ', @pars), OtherPars => join('; ', map $_->[0], @otherpars),
      PMCode => <<EOF,
sub ${main::PDLOBJ}::$func {
  my (@{[join ',', map "\$$_", @pmpars]}) = \@_;
  my (@{[join ',', map "\$$_->[1]", @outputs]});
  @{[ join "\n  ", @defaults ]}
  ${main::PDLOBJ}::_${func}_int(@{[join ',', map "\$$_", @pp_input]});
  @{[!@outputs ? '' : "!wantarray ? \$$outputs[-1][1] : (@{[join ',', map qq{\$$_->[1]}, @outputs]})"]}
}
EOF
    );
    if ($compmode) {
      $hash{Comp} = join '; ', map +($_->[0] =~ /^[A-Z]/ ? $_->[0] : PDL::Type->new($_->[0])->ctype)." $_->[1]", @outputs;
      my $destroy_in = join '', map "$_->[4]($_->[0]_LOCAL);\n", grep !$_->[1], @pdl_inits;
      my $destroy_out = join '', map "$_->[4](\$COMP($_->[0]));\n", grep $_->[1], @pdl_inits;
      $hash{MakeComp} = join '',
        (map "PDL_RETERROR(PDL_err, PDL->make_physical($_->[1]));\n", grep ref, @c_input),
        (map $_->[1] ? "\$COMP($_->[0]) = $_->[5];\n" : "@$_[2,0]_LOCAL = ".$_->[6]->(1).";\n", @pdl_inits),
        (!@pdl_inits ? () : qq{if (@{[join ' || ', map "!".($_->[1]?"\$COMP($_->[0])":"$_->[0]_LOCAL"), @pdl_inits]}) {\n$destroy_in$destroy_out\$CROAK("Error during initialisation");\n}\n}),
        ($callprefix && '$COMP(res) = ').$cfunc."(".join(',', map ref()?"$_->[0](($_->[2]*)($_->[1]->data))[0]":$var2usecomp{$_}?"\$COMP($_)":$_.'_LOCAL', @c_input).");\n",
        $destroy_in;
      $hash{CompFreeCodeComp} = $destroy_out;
      my @map_tuples = map [$_->[1], $var2count{$_->[1]}, @$_[2,3]], grep $var2count{$_->[1]}, @outputs;
      $hash{RedoDimsCode} = join '', map "$_->[2];\n", @map_tuples;
      $hash{Code} = join '', map "$_->[3];\n", @map_tuples;
      $hash{Code} .= $callprefix.'$COMP(res);'."\n" if $callprefix;
    } else {
      my $destroy_in = join '', map "$_->[4]($_->[0]);\n", grep !$_->[1], @pdl_inits;
      my $destroy_out = join '', map "$_->[4]($_->[0]);\n", grep $_->[1], @pdl_inits;
      $hash{Code} = join '',
        (map "@$_[2,0] = ".$_->[6]->(0).";\n", @pdl_inits),
        (!@pdl_inits ? () : qq{if (@{[join ' || ', map "!$_->[0]", @pdl_inits]}) {\n$destroy_in$destroy_out\$CROAK("Error during initialisation");\n}\n}),
        $callprefix.$cfunc."(".join(',', map ref()?"$_->[0]\$$_->[1]()":$var2usecomp{$_}?"\$COMP($_)":$_, @c_input).");\n",
        $destroy_in, $destroy_out;
    }
    pp_def($func, %hash);
}

sub genheader {
  my ($last, $want_new) = @_;
  $want_new //= 1;
  pp_bless("PDL::OpenCV::$last");
  pp_addpm({At=>'Top'},<<"EOPM");
=head1 NAME
\nPDL::OpenCV::$last - PDL bindings for OpenCV $last
\n=cut
\nuse strict;
use warnings;
EOPM
  pp_addhdr qq{#include "opencv_wrapper.h"\n};
  pp_addhdr qq{typedef ${last}Wrapper *PDL__OpenCV__$last;\n} if $want_new;
  pp_addpm(<<EOD) if $want_new;
=head2 new
\n=for ref
\nInitialize OpenCV $last object.
\n=for example
\n  \$obj = PDL::OpenCV::$last->new;
\n=cut
EOD
  pp_addxs(<<EOF) if $want_new;
MODULE = PDL::OpenCV::$last PACKAGE = PDL::OpenCV::$last PREFIX=cw_${last}_
\nPDL__OpenCV__$last cw_${last}_new(char *klass)
\nvoid
cw_${last}_DESTROY(PDL__OpenCV__$last self)
EOF
}

1;

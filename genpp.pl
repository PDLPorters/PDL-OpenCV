use strict;
use warnings;

my $T = [qw(A B S U L F D)];

sub genpp {
    my ($class,$func,$doc,$ismethod,$ret,$opt,@params) = @_;
    die "No class given for method='$ismethod'" if !$class and $ismethod;
    $_ = '' for my ($callprefix, $compmode);
    my (@callargs, @pars, @otherpars, @inits, @outputs, @pmpars, @defaults, %var2count, %var2out);
    my %hash = (GenericTypes=>$T, NoPthread=>1, HandleBad=>0, Doc=>"=for ref\n\n$doc");
    my $pcount = 1;
    push @params, [$ret,'res','',['/O']] if $ret ne 'void';
    for (@params) {
      my ($type, $var, $default, $f) = @$_;
      $default //= '';
      my %flags = map +($_=>1), @{$f||[]};
      push @pmpars, $var;
      my ($partype, $par) = '';
      if ($type eq 'MatWrapper *') {
        $par = "$var(l$pcount,c$pcount,r$pcount)";
        push @inits, [$var, $flags{'/O'}, $type, $pcount];
        $compmode = $var2out{$var} = 1 if $flags{'/O'};
        push @callargs, $var;
        $var2count{$var} = $pcount++;
      } else {
        ($partype = $type) =~ s#\s*\*$##;
        $par = "$var()";
        push @callargs, [($type =~ /\*$/ ? '&' : ''), $var, $partype];
      }
      if ($flags{'/O'}) {
        push @outputs, [$type, $var];
        $default = 'PDL->null' if !length $default;
      }
      push @defaults, "\$$var = $default if !defined \$$var;" if length $default;
      push @pars, join ' ', grep length, $partype, ($flags{'/O'} ? '[o]' : ()), $par;
    }
    $callprefix = '$res() = ', pop @callargs if $ret ne 'void';
    %hash = (%hash,
      Pars => join('; ', @pars), OtherPars => join('; ', @otherpars),
      PMCode => <<EOF,
sub ${main::PDLOBJ}::$func {
  my (@{[join ',', map "\$$_", @pmpars]}) = \@_;
  @{[ join "\n  ", @defaults ]}
  ${main::PDLOBJ}::_${func}_int(@{[join ',', map "\$$_", @pmpars]});
  @{[!@outputs ? '' : "!wantarray ? \$$outputs[-1][1] : (@{[join ',', map qq{\$$_->[1]}, @outputs]})"]}
}
EOF
    );
    if ($compmode) {
      $hash{Comp} = join '; ', map join(' ', @$_), @outputs;
      $callprefix &&= '$COMP(res) = ';
      my $destroy_in = join '', map "cw_Mat_DESTROY($_->[0]_LOCAL);\n", grep !$_->[1], @inits;
      my $destroy_out = join '', map "cw_Mat_DESTROY(\$COMP($_->[0]));\n", grep $_->[1], @inits;
      $hash{MakeComp} = join '',
        (map "PDL_RETERROR(PDL_err, PDL->make_physical($_->[1]));\n", grep ref, @callargs),
        (map $_->[1] ? "\$COMP($_->[0]) = cw_Mat_new(NULL);\n" : "@$_[2,0]_LOCAL = cw_Mat_newWithDims($_->[0]->dims[0],$_->[0]->dims[1],$_->[0]->dims[2],$_->[0]->datatype,$_->[0]->data);\n", @inits),
        (!@inits ? () : qq{if (@{[join ' || ', map "!".($_->[1]?"\$COMP($_->[0])":"$_->[0]_LOCAL"), @inits]}) {\n$destroy_in$destroy_out\$CROAK("Error during initialisation");\n}\n}),
        ($callprefix && '$COMP(res) = ').join('_', grep length,'cw',$class,$func)."(".join(',', map ref()?"$_->[0](($_->[2]*)($_->[1]->data))[0]":$var2out{$_}?"\$COMP($_)":$_.'_LOCAL', @callargs).");\n",
        $destroy_in;
      $hash{CompFreeCodeComp} = $destroy_out;
      my @map_tuples = map [$_->[1], $var2count{$_->[1]}], grep $var2count{$_->[1]}, @outputs;
      $hash{RedoDimsCode} = join '',
        map "cw_Mat_pdlDims(\$COMP($_->[0]), &\$PDL($_->[0])->datatype, &\$SIZE(l$_->[1]), &\$SIZE(c$_->[1]), &\$SIZE(r$_->[1]));\n",
        @map_tuples;
      $hash{Code} = join '',
        map "memmove(\$P($_->[0]), cw_Mat_ptr(\$COMP($_->[0])), \$PDL($_->[0])->nbytes);\n",
        @map_tuples;
      $hash{Code} .= $callprefix.'$COMP(res);'."\n" if $callprefix;
    } else {
      my $destroy_in = join '', map "cw_Mat_DESTROY($_->[0]);\n", grep !$_->[1], @inits;
      my $destroy_out = join '', map "cw_Mat_DESTROY($_->[0]);\n", grep $_->[1], @inits;
      $hash{Code} = join '',
        (map "@$_[2,0] = cw_Mat_newWithDims(\$SIZE(l$_->[3]),\$SIZE(c$_->[3]),\$SIZE(r$_->[3]),\$PDL($_->[0])->datatype,\$P($_->[0]));\n", @inits),
        (!@inits ? () : qq{if (@{[join ' || ', map "!$_->[0]", @inits]}) {\n$destroy_in$destroy_out\$CROAK("Error during initialisation");\n}\n}),
        $callprefix.join('_', grep length,'cw',$class,$func)."(".join(',', map ref()?"$_->[0]\$$_->[1]()":$_, @callargs).");\n",
        $destroy_in, $destroy_out;
    }
    pp_def($func, %hash);
}

1;

use strict;
use warnings;

my $T = [qw(A B S U L F D)];

sub genpp {
    my ($class,$func,$doc,$ismethod,$ret,$opt,@params) = @_;
    die "No class given for method='$ismethod'" if !$class and $ismethod;
    $_ = '' for my ($initstr, $afterstr, $callprefix);
    my (@checks, @callargs, @pars, @otherpars, @outputs, @pmpars, @defaults);
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
        $initstr .= "$type$var = cw_Mat_newWithDims(\$SIZE(l$pcount),\$SIZE(c$pcount),\$SIZE(r$pcount),\$PDL($var)->datatype,\$P($var));\n";
        push @checks, qq{!$var};
        $afterstr .= "cw_Mat_DESTROY($var);\n";
        push @callargs, $var;
        $pcount++;
      } else {
        ($partype = $type) =~ s#\s*\*$##;
        $par = "$var()";
        push @callargs, ($type =~ /\*$/ ? '&' : '') . "\$$var()";
      }
      if ($flags{'/O'}) {
        push @outputs, [$type, $var];
        $default = 'PDL->null' if !length $default;
      }
      push @defaults, "\$$var = $default if !defined \$$var;" if length $default;
      push @pars, join ' ', $partype, ($flags{'/O'} ? '[o]' : ()), $par;
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
    $hash{Code} = join '',
      $initstr,
      (!@checks ? () : qq{if (@{[join ' || ', @checks]}) {\n$afterstr\$CROAK("Error during initialisation");\n}\n}),
      ${callprefix}.join('_', grep length,'cw',$class,$func)."(".join(',', @callargs).");\n",
      $afterstr;
    pp_def($func, %hash);
}

1;

use strict;
use warnings;

my $T = [qw(A B S U L F D)];

sub genpp {
    my ($class,$func,$doc,$ismethod,$ret,$opt,@params) = @_;
    die "No class given for method='$ismethod'" if !$class and $ismethod;
    $_ = '' for my ($callprefix);
    my (@callargs, @pars, @otherpars, @inits, @outputs, @pmpars, @defaults);
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
        push @callargs, $var;
        $pcount++;
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
    my $destroy_in = join '', map "cw_Mat_DESTROY($_->[0]);\n", grep !$_->[1], @inits;
    my $destroy_out = join '', map "cw_Mat_DESTROY($_->[0]);\n", grep $_->[1], @inits;
    $hash{Code} = join '',
      (map "@$_[2,0] = cw_Mat_newWithDims(\$SIZE(l$_->[3]),\$SIZE(c$_->[3]),\$SIZE(r$_->[3]),\$PDL($_->[0])->datatype,\$P($_->[0]));\n", @inits),
      (!@inits ? () : qq{if (@{[join ' || ', map "!$_->[0]", @inits]}) {\n$destroy_in$destroy_out\$CROAK("Error during initialisation");\n}\n}),
      $callprefix.join('_', grep length,'cw',$class,$func)."(".join(',', map ref()?"$_->[0]\$$_->[1]()":$_, @callargs).");\n",
      $destroy_in, $destroy_out;
    pp_def($func, %hash);
}

1;

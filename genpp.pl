use strict;
use warnings;

my $T = [qw(A B S U L F D)];

sub genpp {
    my ($class,$func,$doc,$ismethod,$ret,$opt,@params) = @_;
    die "No class given for method='$ismethod'" if !$class and $ismethod;
    $_ = '' for my ($initstr, $afterstr, $callprefix);
    my (@checks, @callargs, @pars, @otherpars, @returns, @pmpars);
    my $pcount = 1;
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
        push @returns, $var;
      }
      push @pars, join ' ', $partype, ($flags{'/O'} ? '[o]' : ()), $par;
    }
    if ($ret ne 'void') {
      push @pmpars, 'res';
      push @pars, "$ret [o] res()";
      push @returns, 'res';
      $callprefix = '$res() = ';
    }
    my $retstr = !@returns ? '' : "!wantarray ? \$$returns[-1] : (@{[join ',', map qq{\$$_}, @returns]})";
    my $codestr = join '',
      $initstr,
      (!@checks ? () : qq{if (@{[join ' || ', @checks]}) {\n$afterstr\n\$CROAK("Error during initialisation");\n}\n}),
      ${callprefix}.join('_', grep length,'cw',$class,$func)."(".join(',', @callargs).");\n",
      $afterstr;
    my $pmsetnull = join "\n", map "\$$_ = PDL->null if !defined \$$_;", @returns;
    pp_def($func,
           Pars => join('; ', @pars),
           OtherPars => join('; ', @otherpars),
           GenericTypes=>$T,
           NoPthread=>1,
           HandleBad=>0,
           PMCode => qq{
                   sub ${main::PDLOBJ}::$func {
                           my (@{[join ',', map "\$$_", @pmpars]}) = \@_;
                           $pmsetnull
                           ${main::PDLOBJ}::_${func}_int(@{[join ',', map "\$$_", @pmpars]});
                           $retstr
                   }
           },
           Code => $codestr,
           Doc => "=for ref\n\n$doc",
    );
}

1;

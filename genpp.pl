my $T = [qw(A B S U L F D)];

sub genpp {
    my ($class,$func,$doc,$ismethod,$ret,$opt,@params) = @_;
    die "No class given for method='$ismethod'" if !$class and $ismethod;
    $_ = '' for my ($initstr, $afterstr, $callprefix);
    my (@checks, @callargs, @pars, @otherpars, @returns, @pmpars);
    my $pcount = 1;
    for (@params) {
      my ($type, $var) = @$_;
      push @pmpars, $var;
      if ($type eq 'MatWrapper *') {
	push @pars, "$var(l$pcount,c$pcount,r$pcount)";
	$initstr .= "$type$var = cw_Mat_newWithDims(\$SIZE(l$pcount),\$SIZE(c$pcount),\$SIZE(r$pcount),\$PDL($var)->datatype,\$P($var));\n";
	push @checks, qq{!$var};
	$afterstr .= "cw_Mat_DESTROY($var);\n";
	push @callargs, $var;
	$pcount++;
      } else {
	(my $rawtype = $type) =~ s#\s*\*$##;
	push @pars, "$rawtype ".($rawtype ne $type ? '[o]' : '')."$var()";
	push @callargs, ($type =~ /\*$/ ? '&' : '') . "\$$var()";
	push @returns, $var;
      }
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
	   PMCode => qq{
		   sub ${::PDLOBJ}::$func {
			   my (@{[join ',', map "\$$_", @pmpars]}) = \@_;
			   $pmsetnull
			   ${::PDLOBJ}::_${func}_int(@{[join ',', map "\$$_", @pmpars]});
			   $retstr
		   }
	   },
	   Code => $codestr,
	   Doc => "=for ref\n\n$doc",
    );
}

1;

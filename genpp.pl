use strict;
use warnings;
use PDL::Types;

my $T = [qw(A B S U L F D)];

sub genpp_par {
  my ($type, $name, $pcount) = @_;
  my ($is_other, $ctype, $par) = (0, "${type}Wrapper *");
  if ($type eq 'Mat') {
    $par = "$name(l$pcount,c$pcount,r$pcount)";
  } else {
    $par = "PDL__OpenCV__$type $name";
    $is_other = 1;
  }
  ($is_other, $par, $ctype);
}

sub genpp {
    my ($class,$func,$doc,$ismethod,$ret,$opt,@params) = @_;
    die "No class given for method='$ismethod'" if !$class and $ismethod;
    $_ = '' for my ($callprefix, $compmode);
    my (@c_input, @pp_input, @pars, @otherpars, @inits, @outputs, @pmpars, @defaults, %var2count, %var2usecomp);
    my %hash = (GenericTypes=>$T, NoPthread=>1, HandleBad=>0, Doc=>"=for ref\n\n$doc");
    my $pcount = 1;
    my $cfunc = join('_', grep length,'cw',$class,$func);
    unshift @params, [$class,'self'] if $ismethod;
    push @params, [$ret,'res','',['/O']] if $ret ne 'void';
    for (@params) {
      my ($type, $var, $default, $f) = @$_;
      $default //= '';
      my %flags = map +($_=>1), @{$f||[]};
      my ($partype, $par, $is_other) = '';
      if ($type =~ /^[A-Z]/) {
        ($is_other, $par, $type) = genpp_par($type, $var, $pcount);
        if ($is_other) {
          die "Error: OtherPars '$var' is output" if $flags{'/O'};
          push @otherpars, [$par, $var];
          $var2usecomp{$var} = 1;
        } else {
          push @inits, [$var, $flags{'/O'}, $type, $pcount];
          $compmode = $var2usecomp{$var} = 1 if $flags{'/O'};
          $var2count{$var} = $pcount++;
        }
        push @c_input, $var;
      } else {
        ($partype = $type) =~ s#\s*\*$##;
        $par = "$var()";
        push @c_input, [($type =~ /\*$/ ? '&' : ''), $var, $partype];
      }
      if ($flags{'/O'}) {
        push @outputs, [$type, $var];
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
      my $destroy_in = join '', map "cw_Mat_DESTROY($_->[0]_LOCAL);\n", grep !$_->[1], @inits;
      my $destroy_out = join '', map "cw_Mat_DESTROY(\$COMP($_->[0]));\n", grep $_->[1], @inits;
      $hash{MakeComp} = join '',
        (map "PDL_RETERROR(PDL_err, PDL->make_physical($_->[1]));\n", grep ref, @c_input),
        (map $_->[1] ? "\$COMP($_->[0]) = cw_Mat_new(NULL);\n" : "@$_[2,0]_LOCAL = cw_Mat_newWithDims($_->[0]->dims[0],$_->[0]->dims[1],$_->[0]->dims[2],$_->[0]->datatype,$_->[0]->data);\n", @inits),
        (!@inits ? () : qq{if (@{[join ' || ', map "!".($_->[1]?"\$COMP($_->[0])":"$_->[0]_LOCAL"), @inits]}) {\n$destroy_in$destroy_out\$CROAK("Error during initialisation");\n}\n}),
        ($callprefix && '$COMP(res) = ').$cfunc."(".join(',', map ref()?"$_->[0](($_->[2]*)($_->[1]->data))[0]":$var2usecomp{$_}?"\$COMP($_)":$_.'_LOCAL', @c_input).");\n",
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
        $callprefix.$cfunc."(".join(',', map ref()?"$_->[0]\$$_->[1]()":$var2usecomp{$_}?"\$COMP($_)":$_, @c_input).");\n",
        $destroy_in, $destroy_out;
    }
    pp_def($func, %hash);
}

sub genheader {
  my ($last) = @_;
  pp_bless("PDL::OpenCV::$last");
  pp_addpm({At=>'Top'},<<"EOPM");
=head1 NAME

PDL::OpenCV::$last - PDL bindings for OpenCV $last

=cut

use strict;
use warnings;
EOPM
  pp_addhdr <<EOH;
#include "opencv_wrapper.h"
typedef ${last}Wrapper *PDL__OpenCV__$last;
EOH
  pp_addpm(<<EOD);
=head2 new

=for ref

Initialize OpenCV $last object.

=for example

  \$obj = PDL::OpenCV::$last->new;

=cut
EOD

  pp_addxs(<<EOF);
MODULE = PDL::OpenCV::$last PACKAGE = PDL::OpenCV::$last PREFIX=cw_${last}_

PDL__OpenCV__$last cw_${last}_new(char *klass)

void
cw_${last}_DESTROY(PDL__OpenCV__$last self)
EOF
}

1;

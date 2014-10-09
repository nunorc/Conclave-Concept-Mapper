use strict;
use warnings;
package Conclave::Concept::Mapper::Score::kpss;
# ABSTRACT: kPSS based score function

use Lingua::SynSet::kPSS;

sub score {
  my ($terms1, $terms2) = @_;
  my $score = 0;

  my $first = shift @$terms1;
  my $kpss1 = kpss_create(lc $first);
  foreach (@$terms1) {
    $kpss1 = kpss_union($kpss1, kpss_create(lc $_));
  }

  $first = shift @$terms2;
  my $kpss2 = kpss_create(lc $first);
  foreach (@$terms2) {
    $kpss2 = kpss_union($kpss2, kpss_create(lc $_));
  }

  $score = kpss_simil($kpss1, $kpss2) if ($kpss1 and $kpss2);
  
  return $score;
}

1;

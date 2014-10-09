#!perl -T

use Test::More;

my $base = 'Conclave::Concept::Mapper';
use_ok($base);
my $tests = 1;

foreach (qw/Query Rank Rank::Entry Map Map::Cell Locate/) {
  use_ok("${base}::$_") || print "${base}::$_ failed to load!\n";
  $tests++;
}

done_testing($tests);


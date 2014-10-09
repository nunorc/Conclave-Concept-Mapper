#!perl -T

use Test::More tests => 3;
use Conclave::Concept::Mapper::Score::kpss;

my $score;

$score = Conclave::Concept::Mapper::Score::kpss::score(['user'],['user']);
is( $score, 1, 'score same terms' );

$score = Conclave::Concept::Mapper::Score::kpss::score(['user'],['add']);
is( $score, 0, 'score completly different terms' );

$score = Conclave::Concept::Mapper::Score::kpss::score(['user'],['users']);
ok( ($score>0 and $score<1), 'overlapping kpss' );


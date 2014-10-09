use strict;
use warnings;
package Conclave::Concept::Mapper::Locate;
# ABSTRACT: concept mapper search and locate features

use Conclave::Concept::Mapper;
use Conclave::Concept::Mapper::Query;
use Conclave::Concept::Mapper::Rank;
use Conclave::OTK;

use JSON;
use File::Slurp qw/write_file read_file/;
use List::Util qw/sum/;
use Text::Levenshtein qw(distance);
use Data::Dumper;  # FIXME

use Lingua::SynSet::kPSS;

our $DEBUG = 1;

sub new {
  my ($class, %otks) = @_;
  my $init = { };
  foreach (keys %otks) {
    $init->{otks}->{$_} = $otks{$_};
  }
  my $self = bless($init, $class);
  #$self->{score} = 'Con

  return $self;
}

sub locate {
  my ($self, $query_string) = @_;

  # parse query
  $self->{query} = Conclave::Concept::Mapper::Query->new($query_string);

  _debug("getting elements") if $DEBUG;
  my @elements = get_elements($self, $self->{query});
  my $total = scalar @elements;

  my $rank = Conclave::Concept::Mapper::Rank->new(entries=>[]); # FIXME remove []
  my $count = 1;
  foreach my $e (@elements) {
    _debug("processing $e ($count/$total)") if $DEBUG;
    $count++;
    my $score = _compute_score($self, $e);

=head1 aggr
    my @aggr = @{ $self->{query}->aggr } if $self->{query}->aggr;
    my @a_scores;

    if (@aggr) {
      foreach my $a (@aggr) {
        my @es = get_elements_aggr($self->{query}->pkgid, $self->{query}->onto, $e, $a);
        foreach my $i (@es) {
          push @a_scores, _compute_score($self->{query}, $i);
        }
      }
    }
    my $avg = 0;
    $avg = sum(@a_scores) / scalar(@a_scores) if @a_scores;;
    if ($avg > 0) {
      $score = $score * 0.5 + $avg * 0.5;
    }
=cut

    my $entry = Conclave::Concept::Mapper::Rank::Entry->new(
                  score => $score,
                  element => $e,
                );
    $rank->add_entry($entry);
    _debug("score $score") if $DEBUG;
  }

  return $rank;
}

my %stash;

# score dispatcher
sub _compute_score {
  my ($locator, $element) = @_;
  my $score = 0;

  my $fscore = $locator->{query}->{score} || 'kpss';
  $fscore = "Conclave::Concept::Mapper::Score::$fscore";

  my @terms1 = get_terms($locator, $element);
  my @terms2 = @{ $locator->{query}->workd };
print "terms1\n",Dumper(\@terms1);
print "terms2\n",Dumper(\@terms2);

  #$score = $score->score([@terms1], [@terms2]);
  
  return $score;
}

sub _compute_score_kpss {
  my ($locator, $element) = @_;
  my $score = 0;

  # FIXME 
  my $t = get_terms($locator, $element);
  return 0 unless ($t and $t->{terms});

  my @terms = split /,/, $t->{terms};
  return 0 unless @terms;

  my $first = shift @terms;
  return 0 unless $first;

  my $kpss1 = kpss_create(lc $first);
  if (@terms > 0) {
    foreach (@terms) {
      $kpss1 = kpss_union($kpss1, kpss_create(lc $_));
    }
  }

  return 0 unless ($stash{kpss} and $kpss1);
  $score = kpss_simil($stash{kpss}, $kpss1);

  return $score;
}

sub _compute_query_kpss {
  my ($query) = @_;

  my @terms = @{ $query->word };
  my $first = shift @terms;
  return undef unless $first;

  my $kpss = kpss_create(lc $first);
  if (@terms > 0) {  
    foreach (@terms) {
      $kpss = kpss_union($kpss, kpss_create(lc $_));
    }
  }

  return $kpss;
}

sub _compute_score_match {
  my ($locator, $element) = @_;
  my $score = 0;

  my $t = get_terms($locator, $element);
  return 0 unless ($t and $t->{terms});

  my @element_terms = split /,/, $t->{terms};
  my @query_terms = @{ $locator->{query}->{word} };

  my $equal = 0;
  foreach my $i (@element_terms) {
    foreach my $j (@query_terms) {
      $equal++ if (lc($i) eq lc($j));
    }
  }

  if (scalar @element_terms > scalar @query_terms) {
    $score = $equal / scalar(@element_terms);
  }
  else {
    $score = $equal / scalar(@query_terms);
  }

  return $score;
}

sub _debug {
  my $msg = shift;

  my $time = localtime;
  print STDERR "[$time] $msg\n", 
}

1;

__END__

=head1 SYNOPSIS

    use Conclave::Mapper::Locate;

    my $l = Conclave::Mapper::Locate->new();
    $l->locate($query_string);

=head1 DESCRIPTION

TODO

=func locate

Calculate rank for a query.


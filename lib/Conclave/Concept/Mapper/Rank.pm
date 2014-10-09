package Conclave::Concept::Mapper::Rank;
# ABSTRACT: object for storing a rank

use Moo;
use Conclave::Concept::Mapper::Rank::Entry;

has entries => ( is => 'rw' );

sub add_entry {
  my ($self, $new) = @_;

  push @{$self->entries}, $new;
}

sub sorted {
  my ($self, $order) = @_;
  $order = 'desc' unless $order;

  my @entries;
  if ($order =~ m/^asc$/i) {
    @entries = sort {$a->score <=> $b->score} @{ $self->entries };
  }
  else {
    @entries = sort {$b->score <=> $a->score} @{ $self->entries };
  }
  
  return @entries;
}

sub summary {
  my ($self, $new) = @_;
  my %summary;

  my $total = @{$self->entries} || 0;
  $summary{total} = $total;
 
  return %summary;
}

1;

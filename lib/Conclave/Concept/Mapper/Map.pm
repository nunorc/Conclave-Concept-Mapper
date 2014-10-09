package Conclave::Mapper::Map;
# ABSTRACT: object for storing a map


use Moo;

has cells => ( is => 'rw' );
has function => ( is => 'rw');

sub add_cell {
  my ($self, $new) = @_;

  push @{$self->cells}, $new;
}

sub get_cell {
  my ($self, $row, $col) = @_;

  foreach (@{$self->cells}) {
    return $_ if ($_->row eq $row and $_->col eq $col);
  }

  return undef;
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

sub rank {
  my ($self) = @_;

  if ($self->function eq 'levenshtein') {
    return [sort __asc @{ $self->cells }];
  }
  else {
    return [sort __desc @{ $self->cells }];
  }
  
  return [];
}

sub __asc { $a->{score} <=> $b->{score} }
sub __desc { $b->{score} <=> $a->{score} }

1;

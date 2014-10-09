use strict;
use warnings FATAL => 'all';
package Conclave::Concept::Mapper::Query;
# ABSTRACT: query object for the concept mapper

sub new {
  my ($class, $string) = @_;

  my $self = bless( {onto=>'program'}, $class);
  $self->parse_query_string($string);

  return $self;
}

sub parse_query_string {
  my ($self, $string) = @_;

  my $res = { };
  if ($string =~ m/\[(.*?)\]/) {
    while ($string =~ m/(\w+)=(\w+)/g) {
      push @{ $res->{$1} }, $2;
    }
    $res->{score} = shift @{$res->{score}} if $res->{score};
  }
  else {
    my @words = split /\s+/, $string;
    $res->{word} = [@words];
  }

  # FIXME
  $self->class($res->{class});
  $self->score($res->{score});
  $self->word($res->{word});
  $self->aggr($res->{aggr});
  $self->onto(shift @{ $res->{onto} }) if $res->{onto};
}

sub class {
  my ($self, $class) = @_;
  $self->{class} = $class if $class;
  return $self->{class};
}
sub add_class {
  my ($self, $class) = @_;
  push @{$self->{class}}, $class;
}
sub score {
  my ($self, $score) = @_;
  $self->{score} = $score if $score;
  return $self->{score};
}
sub word {
  my ($self, $word) = @_;
  $self->{word} = $word if $word;
  return $self->{word};
}
sub add_word {
  my ($self, $word) = @_;
  push @{$self->{word}}, $word;
}
sub aggr {
  my ($self, $aggr) = @_;
  $self->{aggr} = $aggr if $aggr;
  return $self->{aggr};
}
sub add_aggr {
  my ($self, $aggr) = @_;
  push @{$self->{aggr}}, $aggr;
}
sub onto {
  my ($self, $onto) = @_;
  $self->{onto} = $onto if $onto;
  return $self->{onto};
}
sub pkgid {
  my ($self, $pkgid) = @_;
  $self->{pkgid} = $pkgid if $pkgid;
  return $self->{pkgid};
}

1;

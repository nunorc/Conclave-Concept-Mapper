use strict;
use warnings;
package Conclave::Concept::Mapper;
# ABSTRACT: concept mapper framework

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw/get_elements get_elements_aggr get_terms/;

use Conclave::OTK;

use JSON;
use File::Slurp qw/write_file read_file/;
use CHI;

my $CACHE = CHI->new(
                driver   => 'File',
                root_dir => '/tmp/conc-cache'
              );

sub get_elements {
  my ($locator, $query) = @_;

  # FIXME maybe default?
  my $onto = $query->onto;
  $onto = 'program' unless $onto;

  # create ontology interface
  unless (exists $locator->{otks}->{$query->onto}) {
    warn 'OTK not found for alias: '.$query->onto;
    return;
  }
  my $otk = $locator->{otks}->{$query->onto};

  # set classes
  my @init;
  push @init, 'ProgramElement' if $query->onto eq 'program';
  push @init, 'Concept' if $query->onto eq 'problem';
  if ($query->class) {
    @init = @{ $query->class };
  }

  # get classes subclasses
  my %classes;
  foreach my $c (@init) {
    $classes{$c}++;
    foreach ($otk->get_all_subclasses($c)) {
      next if $_ =~ m/Identifier$/;  # FIXME
      $classes{$_}++;
    }
  }
  my @classes = keys %classes;

  # get instances for all classes found
  my @instances;
  foreach (@classes) {
    push @instances, $otk->get_instances($_);
  }

  return @instances;
}

sub get_elements_aggr {
  my ($pkgid, $onto, $e, $aggr) = @_;

  my @elements;
  #my @l = split /\//, $e;
  #my $pkgid = $l[-2];
  #my ($onto, $id) = split /#/, $l[-1];
  if ($e and $pkgid and $onto and $aggr) {
    my $o = Conclave::Utils::OTK->new($pkgid, $onto);
    my $sparql = <<"EOQ";
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>

SELECT ?o WHERE {
  ?o <http://conclave.di.uminho.pt/owl/$pkgid/$onto#$aggr> <$e>
}
EOQ

    my $r = $o->__query($sparql);
    @elements = split /\n+/, $r;
    @elements = map {s/^<//; $_} @elements;
    @elements = map {s/>$//; $_} @elements;
    @elements = grep(!/^\?/, @elements);
  }

  return @elements;
}

sub get_terms {
  my ($locator, $instance) = @_;

  my $key = "terms_$instance";
  my $new = $CACHE->get($key);
  return $new if $new;

  $new = { uid => $instance };

  # problem ontology
  if ($locator->{query}->onto eq 'problem') {
    if ($instance =~ m/.*?#(.*)/) {
      $new->{terms} = $1;
    }
    else {
      return undef;
    }
  }
  # program ontology
  else {
    my $iid = $instance;
    $iid =~ s/#/#I::/;

    my $o = $locator->{otks}->{$locator->{query}->onto};
    my @data = $o->get_data_props($iid);
    foreach (@data) {
      next unless (scalar(@data)==3);

      if ($_->[1] =~ m/#hasSplits$/) {
        $new->{splits} = $1 if $_->[2] =~ m/\"?(.*?)\"?\^\^/;
      }
      if ($_->[1] =~ m/#hasTerms$/) {
        $new->{terms} = $1 if $_->[2] =~ m/\"?(.*?)\"?\^\^/;
      }
    }
  }

  $CACHE->set($key, $new);
  return $new;
}

1;

__END__

=encoding UTF-8

=head1 SYNOPSIS

  TODO

=head1 DESCRIPTION

  TODO

=func get_elements

Get the set of elements from the ontology based on query requirements.

=func get_elements_aggr

Get the set of elements from the ontology based on query requirements,
including aggregated elements defined by the query.

=func get_terms

Get set of splits and terms for one instance.

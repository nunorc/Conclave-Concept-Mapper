package Conclave::Mapper::Mapping;

use 5.006;
use strict;
use warnings FATAL => 'all';

use lib '/home/smash/playground/natura.svn.main/Conclave/Conclave-PSS/lib';  # FIXME
use lib '/home/smash/playground/natura.svn.main/Conclave/Conclave-kPSS/lib';  # FIXME

use Conclave::Mapper;
use Conclave::Mapper::Map;
use Conclave::Mapper::Map::Cell;
use Conclave::Mapper::Query;
use Conclave::Utils::OTK;
use Conclave::PSS;
use Conclave::Utils::OTK;
use Lingua::SynSet::kPSS;

use JSON;
use File::Slurp qw/write_file read_file/;
use List::Util qw/sum/;
use Data::Dumper;  # FIXME
use Text::Levenshtein qw(distance);

=head1 NAME

Conclave::Mapper::Mapping - define mapping functions

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our $HOME = '/home/smash/conclave-website-root'; # FIXME?
our $OWLROOT = "$HOME/owl"; # FIXME?

=head1 SYNOPSIS

    use Conclave::Mapper::Mapping;

    my $m = Conclave::Mapper::Mapping->new($pkgid);
    $m->map($query1, $query2);

=head1 METHODS

=head2 new

New locate object.

=cut

sub new {
  my ($class, $pkgid) = @_;
  my $init = {
      pkgid => $pkgid,
      onto => 'program',
    };
  my $self = bless($init, $class);

  return $self;
}

=head2 map

Calculate a map.

=cut

my %stash;

sub map {
  my ($self, $q1, $q2, $f) = @_;

  # parse queries
  $self->{q1} = Conclave::Mapper::Query->new($self->{pkgid}, $q1);
  $self->{q2} = Conclave::Mapper::Query->new($self->{pkgid}, $q2);

  my @els1 = get_elements($self->{q1});
  my @els2 = get_elements($self->{q2});

  my $map = Conclave::Mapper::Map->new(cells=>[],function=>$f); # FIXME remove []

  foreach my $e1 (@els1) {
    foreach my $e2 (@els2) {
      my $score = $self->compute_score($e1, $e2, $f);
      next unless $score > 0;

      my $cell = Conclave::Mapper::Map::Cell->new(
                  row => $e1,
                  col => $e2,
                  score => $score,
                );
      $map->add_cell($cell);
    }
  }

  return $map;
}

my %dispatch = ( pss => \&compute_score_pss,
                 kpss => \&compute_score_kpss,
                 levenshtein => \&compute_score_levenshtein,
              );

sub compute_score {
  my ($self, $e1, $e2, $f) = @_;
  my $score = 0;

  $f = $dispatch{$f || 'pss'};
  $score = $f->($self, $e1, $e2);

  return $score;
}

sub compute_score_pss {
  my ($mapping, $e1, $e2) = @_;
  my $pkgid = $stash{pkgid};
  my $score = 0;

  #my $t1 = get_terms($mapping->{q1},$e1);
  #return 0 unless $t1;
  #my @terms1 = split /,/, $t1->{terms};
  #my $t2 = get_terms($mapping->{q2},$e2);
  #return 0 unless $t2;
  #my @terms2 = split /,/, $t2->{terms};

  my $pss1 = get_pss($mapping->{q1}, $e1);
  my $pss2 = get_pss($mapping->{q2}, $e2);
  return 0 unless ($pss1 and $pss2);

  my $o = Conclave::PSS->new;
  $score = $o->simil($pss1, $pss2);

  return $score;
}

sub compute_score_kpss {
  my ($mapping, $e1, $e2) = @_;
  my $pkgid = $stash{pkgid};
  my $score = 0;

  my $t1 = get_terms($mapping->{q1},$e1);
  return 0 unless $t1->{terms};
  my @terms1 = split /,/, $t1->{terms};

  my $t2 = get_terms($mapping->{q2},$e2);
  return 0 unless $t2->{terms};
  my @terms2 = split /,/, $t2->{terms};

  my $f1 = shift @terms1;
  return 0 unless $f1;
  my $kpss1 = kpss_create($f1);
  if (@terms1 > 0) {
    foreach (@terms1) {
      $kpss1 = kpss_union($kpss1, kpss_create($_));
    }
  }

  my $f2 = shift @terms2;
  return 0 unless $f2;
  my $kpss2 = kpss_create($f2);
  if (@terms2 > 0) {
    foreach (@terms2) {
      $kpss2 = kpss_union($kpss2, kpss_create($_));
    }
  }

  return 0 unless ($kpss1 and $kpss2);
  my $o = Conclave::PSS->new;
  $score = $o->simil(kpss_flatten($kpss1), kpss_flatten($kpss2));


  return $score;
}

sub __get_terms {
  my ($e) = @_;
  my @terms;

  my $x = $e;
  $x =~ s/.*?#//;
  if ($e =~ m/program/) {
    my $filename = "$HOME/data/tree-1.5.3/splits_oracle.json";
    my $json = read_file($filename, {binmode=>':utf8'});
    my $data = decode_json $json;
    
    push @terms, @{$data->{terms}};
  }
  if ($e =~ m/problem/) {
    push @terms, $x;
  }

  return @terms;
}

sub compute_score_levenshtein {
  my ($mapping, $e1, $e2) = @_;
  my $score = 0;
  
  my $t1 = get_terms($mapping->{q1}, $e1);
  my $t2 = get_terms($mapping->{q2}, $e2);

  return -1 unless ($t1->{terms} and $t2->{terms});
  my @e1_terms = split /,/, $t1->{terms};
  my @e2_terms = split /,/, $t2->{terms};

  my @values;
  foreach my $t1 (@e1_terms) {
    foreach my $t2 (@e2_terms) {
      my $d = distance($t1, $t2);
      push @values, $d;
    }
  }

  if (@values) {
    $score = sum(@values) / scalar(@values);
  }

  return $score;
}

=head1 AUTHOR

Nuno Carvalho, C<< <smash at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-conclave-mapper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Conclave-Mapper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Conclave::Mapper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Conclave-Mapper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Conclave-Mapper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Conclave-Mapper>

=item * Search CPAN

L<http://search.cpan.org/dist/Conclave-Mapper/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nuno Carvalho.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Conclave::Mapper

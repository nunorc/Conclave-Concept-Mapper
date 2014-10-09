package Conclave::Concept::Mapper::Rank::Entry;
# ABSTRACT: object to store an entry in a rank

use Moo;

has score   => ( is => 'rw' );
has element => ( is => 'rw' );

1;

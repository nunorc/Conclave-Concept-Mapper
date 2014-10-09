package Conclave::Mapper::Map::Cell;
# ABSTRACT: object for storing a cell in a map

use Moo;

has score   => ( is => 'rw' );
has row     => ( is => 'rw' );
has col     => ( is => 'rw' );
has element => ( is => 'rw' );

1;

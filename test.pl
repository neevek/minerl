#!/usr/bin/perl

use warnings;
use strict;
use 5.10.0;

package Person;

use Minerl::BaseObject;
our @ISA = qw(Minerl::BaseObject);


sub get {
    my ($self, $key) = @_;
    return $self->{$key};
}

package main;

my $p = new Person(name => "neevek"); 
say $p->get("name");

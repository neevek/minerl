#!/usr/bin/perl

use warnings;
use strict;
use 5.10.0;

#package Person;

#use Minerl::BaseObject;
#our @ISA = qw(Minerl::BaseObject);


#sub get {
    #my ($self, $key) = @_;
    #return $self->{$key};
#}

#package main;

#my $p = new Person(name => "neevek"); 
#say $p->get("name");
    
use Minerl::TemplateManager;

#my $tm = new Minerl::TemplateManager(template_dir => ".", template_suffix => ".html");
my $tm = new Minerl::TemplateManager(template_suffix => ".html");

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
use Minerl::Page;
use Data::Dumper;

#my $tm = new Minerl::TemplateManager(template_dir => ".", template_suffix => ".html");
my $tm = new Minerl::TemplateManager(template_suffix => ".html");

my $p = new Minerl::Page( filename => "posts/index.md" );

#say Data::Dumper->Dump([$p->headers]);

#say $p->headers;

say $tm->applyTemplate($p->header("layout"), $p->content, $p->headers);

#my $p = new Minerl::Page( filename => "templates/default.html" );
##say $p->content;

#say $p->header("footer");

#my $h = $p->headers;
#while (my ($k, $v) = each %$h) {
    #say "$k => $v";
#}

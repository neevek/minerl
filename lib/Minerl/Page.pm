=head1 
    Page is an abstraction of the content of a file that
    is composed of a header section and a content section.
=cut

use strict;
use warnings;
use 5.10.0;

package Minerl::Page;

use Minerl::BaseObject;
our @ISA = qw(Minerl::BaseObject);

use Minerl::Util;

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    my $filename = $self->{"filename"};
    die "Must pass in filename of the page." if !$filename;
    Minerl::Util::parseFile($filename, $self);
   
    return $self;
}

sub field {
    my ($self, $key) = @_;
    return $self->{"fields"}->{$key};
}

sub fields {
    my ($self) = @_;
    return $self->{"fields"};
}

sub content {
    my ($self) = @_;
    return $self->{"fields"}->{"content"};
}

1;

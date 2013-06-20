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

sub header {
    my ($self, $key) = @_;
    return $self->{"headers"}->{$key};
}

sub headers {
    my ($self) = @_;
    return $self->{"headers"};
}

sub content {
    my ($self) = @_;
    return $self->{"content"};
}

1;

use strict;
use warnings;

package Minerl::BaseObject;

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, ref($class) || $class;

    $self->_init(%args);
    $self->{"DEBUG"} = 1;

    return $self;
}

sub _init {
    my ($self, %args) = @_;
    while (my ($key, $value) = each (%args)) {
        $self->{$key} = $value; 
    }
}

1;

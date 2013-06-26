=head1 NAME

Minerl::BaseObject - the base object to be inherited from in the C<minerl> project

=head1 SYNOPSIS

    use Minerl::BaseObject;
    our @ISA = qw(Minerl::BaseObject);

=head1 DESCRIPTION

This class implements a contructor that takes a C<HASH> as parameter, so
any other class that takes parameter as a C<HASH> can inherit from it, which
avoids duplicating the code

=head1 AUTHOR

neevek, C<< <i at neevek.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 neevek.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

package Minerl::BaseObject;

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, ref($class) || $class;

    $self->_init(%args);

    return $self;
}

sub _init {
    my ($self, %args) = @_;
    while (my ($key, $value) = each (%args)) {
        $self->{$key} = $value; 
    }
}

1;

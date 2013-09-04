=head1 NAME

Minerl::Template - A class that encapsulates C<HTML::Template>

=head1 SYNOPSIS
    
    use Minerl::Template;
    my $tmpl = new Minerl::Template( filename => $filename, name => $name );
    $content = $tmpl->apply($content, $options);
    ...

=head1 DESCRIPTION

This class encapsulates C<HTML::Template>, and uses C<HTML::Template> to expand variables set
in the templates and pages.

=head1 AUTHOR

neevek, C<< <i at neevek.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 neevek.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

package Minerl::Template;

use HTML::Template;
our @ISA = qw(Minerl::Page);

sub build {
    my ($self) = @_; 
    $self->{template} = HTML::Template->new_scalar_ref($self->content, die_on_bad_params => 0, loop_context_vars => 1);
}

sub apply {
    my ($self, $content, $options) = @_; 

    my $tmpl = $self->{template};   

    $tmpl or die "Template '" . $self->{name} . "' not prepared, call build() first.";

    $tmpl->clear_params();

    if (ref($options) eq "HASH") {
        $tmpl->param($options);
    } elsif (ref($options) eq "ARRAY") {
        foreach my $option (@$options) {
            if (ref($option) eq "HASH") {
                $tmpl->param($option);
            }
        }
    }
    $tmpl->param( content => $$content );


    return \$tmpl->output(); 
}

sub built {
    my ($self) = @_; 
    return $self->{template} ? 1 : undef;
}

1;

=head1 NAME

Minerl::Formatter::Perl - Encapsulates C<Text::Template>

=head1 SYNOPSIS

    use Minerl::Formatter::Perl;
    my $formatter = new Minerl::Formatter::Perl();
    $content = $formatter->format($$content);

=head1 DESCRIPTION

This class uses C<Text::Template> to process content of pages

=head1 AUTHOR

neevek, C<< <i at neevek.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 neevek.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=head1 SUBROUTINES/METHODS

=cut

package Minerl::Formatter::Perl;
{

my $instance;

=head2

Constructor, which instantiates singleton of C<Minerl::Formatter::Perl> 

=cut

sub new {
    my $class = shift;

    if (!$instance) {
        $instance = bless {}, $class;

        my $useStr = "use Text::Template;";
        eval($useStr);
        $instance->{"available"} = !$@;
    }

    return $instance;
}

=head2

Note: the C<$content> arguement is a B<reference to string>

=cut

sub format { 
    my ($self, $content, $data) = @_;

    if ($self->{"available"}) {
        my $txtTmpl = Text::Template->new(
            TYPE => "STRING",
            SOURCE => $$content,
            DELIMITERS => [ "{{", "}}" ]
        ); 

        return $txtTmpl->fill_in( HASH => $data );
    }
    return $$content;
}

1;
}

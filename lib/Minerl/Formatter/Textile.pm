=head1 NAME

Minerl::Formatter::Textile - Encapsulates C<Text::Textile>

=head1 SYNOPSIS

    use Minerl::Formatter::Textile;
    my $formatter = new Minerl::Formatter::Textile();
    $content = $formatter->format($$content);

=head1 DESCRIPTION

This class uses C<Text::Textile> to process content of pages

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

package Minerl::Formatter::Textile;
{
my $instance;
my $textileInstance;

=head2

Constructor, which instantiates singleton of C<Minerl::Formatter::Textile> 

=cut

sub new {
    my $class = shift;

    if (!$instance) {
        $instance = bless {}, $class;

        my $useStr = "use Text::Textile;";
        eval($useStr);
        $instance->{available} = !$@;

        $textileInstance = new Text::Textile if !$@;
    }

    warn "Warning: Text::Textile is not installed, Textile text will not be parsed." if !$instance->{available};

    return $instance;
}

=head2

Note: the C<$content> arguement is a B<reference to string>

=cut

sub format { 
    my ($self, $content) = @_;
    return $textileInstance ? $textileInstance->process($$content) : $$content;
}

1;
}

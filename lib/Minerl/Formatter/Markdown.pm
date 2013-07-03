=head1 NAME

Minerl::Formatter::Markdown - Encapsulates C<Text::MultiMarkdown>

=head1 SYNOPSIS

    use Minerl::Formatter::Markdown;
    my $formatter = new Minerl::Formatter::Markdown();
    $content = $formatter->format($$content);

=head1 DESCRIPTION

This class uses C<Text::MultiMarkdown> to process content of pages

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

package Minerl::Formatter::Markdown;
{
my $instance;
my $markdownInstance;

=head2

Constructor, which instantiates singleton of C<Minerl::Formatter::Markdown> 

=cut

sub new {
    my $class = shift;

    if (!$instance) {
        $instance = bless {}, $class;

        my $useStr = "use Text::MultiMarkdown;";
        eval($useStr);
        $instance->{available} = !$@;

        $markdownInstance = Text::MultiMarkdown->new(
            empty_element_suffix => '>',
            tab_width => 4,
            use_wikilinks => 0,
        ) if !$@;
    }

    warn "Warning: Text::MultiMarkdown is not installed, Markdown text will not be parsed." if !$instance->{available};

    return $instance;
}

=head2

Note: the C<$content> arguement is a B<reference to string>

=cut

sub format { 
    my ($self, $content) = @_;
    return $markdownInstance ? $markdownInstance->markdown($$content) : $$content;
}

1;
}

use strict;
use warnings;
use 5.10.0;

package Minerl::Formatter::Perl;

my $instance;

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

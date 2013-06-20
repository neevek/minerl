use strict;
use warnings;
use 5.10.0;

package Minerl::Formatter::Markdown;

my $instance;

sub new {
    my $class = shift;

    if (!$instance) {
        $instance = bless {}, $class;

        my $useStr = "use Text::Markdown;";
        eval($useStr);
        $instance->{"available"} = !$@;
    }

    return $instance;
}

sub format { 
    my ($self, $content) = @_;
    return $self->{"available"} ? Text::Markdown::markdown($content) : $content;
}

1;

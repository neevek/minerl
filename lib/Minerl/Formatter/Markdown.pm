use strict;
use warnings;
use 5.10.0;

package Minerl::Formatter::Markdown;

my $instance;
my $markdownInstance;

sub new {
    my $class = shift;

    if (!$instance) {
        $instance = bless {}, $class;

        my $useStr = "use Text::MultiMarkdown;";
        eval($useStr);
        $instance->{"available"} = !$@;

        $markdownInstance = Text::MultiMarkdown->new(
            empty_element_suffix => '>',
            tab_width => 4,
            use_wikilinks => 1,
        ) if !$@;
    }

    warn "Warning: Text::MultiMarkdown is not installed, Markdown text will not be parsed." if !$instance->{"available"};

    return $instance;
}

sub format { 
    my ($self, $content) = @_;
    return $markdownInstance ? $markdownInstance->markdown($$content) : $$content;
}

1;

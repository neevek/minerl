use strict;
use warnings;
use 5.10.0;

package Minerl::Template;

use Minerl::Page;
use HTML::Template;
our @ISA = qw(Minerl::Page);

sub build {
    my ($self) = @_; 
    $self->{"template"} = HTML::Template->new_scalar_ref($self->content, die_on_bad_params => 0, loop_context_vars => 1);
}

sub apply {
    my ($self, $content, $options) = @_; 

    my $tmpl = $self->{"template"};   

    if (!$tmpl) {
        die "Template '" . $self->{"name"} . "' not prepared, call build() first.";
    }

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
    return $self->{"template"} ? 1 : undef;
}

1;

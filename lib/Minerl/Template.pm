use strict;
use warnings;
use 5.10.0;

package Minerl::Template;

use Minerl::Page;
our @ISA = qw(Minerl::Page);

sub build {
    my ($self, $baseTmpl) = @_; 
    if ($baseTmpl) {
        $self->{"fields"}->{"content"} = $baseTmpl->apply( { content => $self->content } ); 
    }

    return $self->{"template"} = HTML::Template->new_scalar_ref(\$self->content, die_on_bad_params => 0);
}

sub apply {
    my ($self, $options) = @_; 

    my $tmpl = $self->{"template"};   

    if (!$tmpl) {
        die "Template '" . $self->{"name"} . "' not prepared, call build() first.";
    }

    $tmpl->clear_params();
    $tmpl->param($options);

    #say ">>>>>>>>>>>>>>>>>>>";
    #use Data::Dumper;
    #say Data::Dumper->Dumper([$options]);
    #say "22>>>>>>>>>>>>>>>>>>>";

    return $tmpl->output(); 
}

sub built {
    my ($self) = @_; 
    return $self->{"template"} ? 1 : undef;
}

1;
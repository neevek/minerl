=head1 NAME

Minerl::TemplateManager - Manages all templates of the site

=head1 SYNOPSIS

    use Minerl::Template;
    my $tm = new Minerl::TemplateManager(template_dir => $templateDir, template_suffix => $templateSuffix);
    my $html = $tm->applyTemplate("layout_name", "...content..." , [ {options1}, {options2}, ... ] );
    ...

=head1 DESCRIPTION

This class reads all files with C<tempalte_suffix> under C<template_dir> as templates, 
these templates can be applied on the pages to generate rendered HTML pages.

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
package Minerl::TemplateManager;

our @ISA = qw(Minerl::BaseObject);

use File::Basename;

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    my $templateDir = $self->{template_dir};
    my $templateSuffix = $self->{template_suffix};

    $self->_initTemplates($templateDir, $templateSuffix);
   
    return $self;
}

sub _initTemplates {
    my ($self, $templateDir, $templateSuffix) = @_;

    -d $templateDir or die "$templateDir: $!";
    my @files = glob($templateDir . "/*" . $templateSuffix);

    my $tmplHashes = $self->{templates} = {};

    foreach my $filename (@files) {
        #print "found template file: $filename\n" if $self->{DEBUG};

        # basename without suffix
        my ($name) = basename($filename) =~ /([^.]+)/;
        $tmplHashes->{$name} = new Minerl::Template( filename => $filename, name => $name );
    }
    
    while (my ($tmplName, $tmpl) = each %$tmplHashes) {
        $tmpl->build();
    }
}

=head2

Applies the templates recursively on the content. that we need recursion is because
templates(or layouts) can be inherited/extended.

=cut

sub applyTemplate {
    my ($self, $tmplName, $content, $options) = @_;

    $content = $self->_applyTemplateRecursively($tmplName, $content, $options);

    return $self->_prettyPrintAvailable ? $self->_prettyPrint($content) : $content;
}

sub _applyTemplateRecursively {
    my ($self, $tmplName, $content, $options) = @_;

    my $tmpl = $self->{templates}->{$tmplName};
    die "Template not found: $tmplName" if !$tmpl;

    $content = $tmpl->apply($content, $options);
    my $baseTmplName = $tmpl->header("layout");
    if ($baseTmplName) {
        return $self->_applyTemplateRecursively($baseTmplName, $content, $options);
    } 
    return $content;
}

sub _prettyPrintAvailable {
    my ($self) = @_;
    return 0;   # pretty print is not used currently, because it is slow

    my $useStr = "
        use HTML::HTML5::Parser qw();
        use HTML::HTML5::Writer qw();
        use XML::LibXML::PrettyPrint qw();
    ";

    eval($useStr);

    return $@ ? undef : 1;
}

sub _prettyPrint {
    my ($self, $content) = @_;

    return \(HTML::HTML5::Writer->new(
        start_tags => 'force',
        end_tags => 'force', 
    )->document(
        XML::LibXML::PrettyPrint->new_for_html(
            indent_string => "\t"
        )->pretty_print(
            HTML::HTML5::Parser->new->parse_string( $content )
        )
    ));
}

1;

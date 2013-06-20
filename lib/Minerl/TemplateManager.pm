use strict;
use warnings;
use 5.10.0;

package Minerl::TemplateManager;

use Minerl::BaseObject;
our @ISA = qw(Minerl::BaseObject);

use Minerl::Util;

use File::Basename;
use Minerl::Template;


use constant {
    PRE_READ => 1,
    READ_HEADER => 2,
    READ_CONTENT => 3 
};

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    my $templateDir = $self->{"template_dir"} || "./templates";
    my $templateSuffix = $self->{"template_suffix"} || ".html";
    $self->_initTemplates($templateDir, $templateSuffix);
   
    return $self;
}

sub _initTemplates {
    my ($self, $templateDir, $templateSuffix) = @_;

    -d $templateDir or die "$templateDir: $!";
    my @files = glob($templateDir . "/*" . $templateSuffix);

    my $tmplHashes = $self->{"templates"} = {};

    foreach my $filename (@files) {
        #print "found template file: $filename\n" if $self->{"DEBUG"};

        # basename without suffix
        my ($name) = basename($filename) =~ /([^.]+)/;
        $tmplHashes->{$name} = new Minerl::Template( filename => $filename, name => $name );
    }
    
    while (my ($tmplName, $tmpl) = each %$tmplHashes) {
        next if $tmpl->built();
        $tmpl->build();
    }
}

sub applyTemplate {
    my ($self, $tmplName, $content, $options) = @_;
    $content = $self->_applyTemplateRecursively($tmplName, $content, $options);

    return $self->_prettyPrintAvailable ? $self->_prettyPrint($content) : $content;
}

sub _applyTemplateRecursively {
    my ($self, $tmplName, $content, $options) = @_;

    my $tmpl = $self->{"templates"}->{$tmplName};
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
    return 0;

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

    return HTML::HTML5::Writer->new(
        start_tags => 'force',
        end_tags => 'force',
    )->document(
        XML::LibXML::PrettyPrint->new_for_html(
            indent_string => "\t"
        )->pretty_print(
            HTML::HTML5::Parser->new->parse_string( $content )
        )
    );
}

1;

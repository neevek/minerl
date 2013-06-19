use strict;
use warnings;
use 5.10.0;

package Minerl::TemplateManager;

use Minerl::BaseObject;
our @ISA = qw(Minerl::BaseObject);

use Minerl::Util;

use File::Basename;
use HTML::Template;

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

    my %tmplPropsHashes;

    foreach my $filename (@files) {
        print "found template file: $filename\n" if $self->{"DEBUG"};

        # basename without suffix
        my ($name) = basename($filename) =~ /([^.]+)/;
        $tmplPropsHashes{$name} = Minerl::Util::parseFile($filename);
    }

    $self->{"templates"} = {};

    foreach my $tmplName (keys %tmplPropsHashes) {
        next if $self->{"templates"}->{$tmplName};

        $self->{"templates"}->{$tmplName} = $self->_buildTemplates(\%tmplPropsHashes, $tmplName);
    }

    foreach my $tmplName (keys %tmplPropsHashes) {
        say "========== $tmplName ==========";
        my $tmplProps = $tmplPropsHashes{$tmplName};
        $self->{"templates"}->{$tmplName}->param(content => "HELLO WORLD!!!");
        say $self->{"templates"}->{$tmplName}->output;
    }
}

sub _buildTemplates {
    my ($self, $tmplPropsHashes, $tmplName) = @_;
    my $tmplProps = $tmplPropsHashes->{$tmplName};

    my $headers = $tmplProps->{"headers"};

    my $baseTmpl; 
    my $baseTmplName = $headers && $headers->{"base"};
    if ($baseTmplName && !$self->{"templates"}->{$baseTmplName}) {

        die "Layout file not found: $baseTmplName - $!" if !$tmplPropsHashes->{$baseTmplName};
        $baseTmpl = $self->_buildTemplates($tmplPropsHashes, $baseTmplName);     

        $self->{"templates"}->{$baseTmplName} = $baseTmpl;
    }

    if ($baseTmpl) {
        $baseTmpl->param(content => $tmplProps->{"content"}); 
        $tmplProps->{"content"} = $baseTmpl->output();
        $baseTmpl->clear_params();
    }

    return HTML::Template->new_scalar_ref(\$tmplProps->{"content"}, die_on_bad_params => 0);
}

sub _applyTemplate {
    my ($self, $tmplName, $options) = @_;

    die "Template not found: $tmplName - $!" if !$self->{"templates"}->{$tmplName};
    
    my $tmpl = $self->{"templates"}->{$tmplName}; 
    $tmpl->clear_param();
    $tmpl->param($options);

    return $tmpl->output(); 
}

1;

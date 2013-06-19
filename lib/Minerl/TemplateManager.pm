use strict;
use warnings;
use 5.10.0;

package Minerl::TemplateManager;

use Minerl::BaseObject;
our @ISA = qw(Minerl::BaseObject);

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
        $tmplPropsHashes{$name} = $self->_parseTemplateFile($filename);
    }

    foreach my $tmplName (keys %tmplPropsHashes) {
        next if $self->{"templates"}->{$tmplName};

        $self->{"templates"}->{$tmplName} = $self->_buildTemplates(\%tmplPropsHashes, $tmplName);
    }

    foreach my $tmplName (keys %tmplPropsHashes) {
        say "========== $tmplName ==========";
        say $self->{"templates"}->{$tmplName}->output;
    }
}

sub _parseTemplateFile {
    my ($self, $filename) = @_;

    my %hash;
    my $content = "";
    my $state = PRE_READ;
    open FILE, "< $filename"; 
    while (my $line = <FILE>) {

        if ($line =~ /^-{3,}$/) {
            if ($state == PRE_READ) {
                $state = READ_HEADER;
                next; # ignore the dashed line
            }
            if ($state == READ_HEADER) {
                $state = READ_CONTENT;
                next; # ignore the dashed line
            }
        } elsif ($state == PRE_READ && $line !~ /^-{3,}$/) {
            $state = READ_CONTENT;
        }

        given ($state) {
            when (READ_HEADER)  {
                # strip leading and trailing white spaces
                $line =~ s/^[ \t]+//g;
                $line =~ s/[ \t\n]+$//g;
                my ($key, $value) = split "[ \t]*:[ \t]*", $line;
                $hash{"headers"}->{$key} = $value;

                #print "HEADER: $key => $value\n";  
            }
            when (READ_CONTENT) {
                $content .= $line; 
            }
        } 
    } 

    $hash{"content"} = $content;

    die "$filename: Header section is not closed." if $state == READ_HEADER;
    close(FILE);

    #print "========CONTENT======$content=====\n" if $content;
    return \%hash;
}

sub _buildTemplates {
    my ($self, $tmplPropsHashes, $tmplName) = @_;
    my $tmplProps = $tmplPropsHashes->{$tmplName};

    say "NAME: $tmplName";

    my $headers = $tmplProps->{"headers"};

    my $tmplDependency; 
    my $tmplDependencyName = $headers && $headers->{"layout"};
    if ($tmplDependencyName && !$self->{"templates"}->{$tmplDependencyName}) {

        die "Layout file not found: $tmplDependencyName" if !$tmplPropsHashes->{$tmplDependencyName};
        $tmplDependency = $self->_buildTemplates($tmplPropsHashes, $tmplDependencyName);     

        $self->{"templates"}->{$tmplDependencyName} = $tmplDependency;
    }

    if ($tmplDependency) {
        $tmplDependency->param(content => $tmplProps->{"content"}); 
        $tmplProps->{"content"} = $tmplDependency->output();
        $tmplDependency->clear_params();
    }

    return HTML::Template->new_scalar_ref(\$tmplProps->{"content"});
}

1;

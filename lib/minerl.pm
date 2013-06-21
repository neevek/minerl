use strict;
use warnings;
use 5.10.0;

package Minerl;

use Minerl::BaseObject;
our @ISA = qw(Minerl::BaseObject);

use Minerl::TemplateManager;
use Minerl::PageManager;

use Config::IniFiles;
use File::Path qw(make_path);
use File::Find qw(find);
use File::Copy qw(copy); 

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    $self->_initConfigFile();

    return $self;
}

sub _initConfigFile {
    my ($self) = @_;

    my $cfgFile = $self->{"cfg_file"};
    -f $cfgFile or die "minerl.cfg not found.";

    tie my %cfg, 'Config::IniFiles', ( -file => $cfgFile );

    $cfg{"system"} = {} if !$cfg{"system"};
    $cfg{"system"}->{"output_dir"} = "out" if !$cfg{"system"}->{"output_dir"};
    $cfg{"system"}->{"raw_dir"} = "raw" if !$cfg{"system"}->{"raw_dir"};
    $cfg{"system"}->{"page_dir"} = "pages" if !$cfg{"system"}->{"page_dir"};
    $cfg{"system"}->{"page_suffix_regex"} = "\\.(?:md|markdown|html)\$" if !$cfg{"system"}->{"page_suffix_regex"};
    $cfg{"system"}->{"template_dir"} = "templates" if !$cfg{"system"}->{"template_dir"};
    $cfg{"system"}->{"template_suffix"} = ".html" if !$cfg{"system"}->{"template_suffix"};

    $cfg{"template"} = {} if !$cfg{"template"};

    $self->{"cfg"} = \%cfg;
}

sub _generatePages {
    my ($self) = @_;

    my $cfg = $self->{"cfg"};
    my $pageDir = $cfg->{"system"}->{"page_dir"};
    -d $pageDir or die "$pageDir does not exist.";

    my $templateDir = $cfg->{"system"}->{"template_dir"};
    -d $templateDir or die "$templateDir does not exist.";

    my $outputDir = $cfg->{"system"}->{"output_dir"};
    make_path($outputDir, { mode => 0755 });

    my $templateSuffix = $cfg->{"system"}->{"template_suffix"};
    my $pageSuffixRegex = $cfg->{"system"}->{"page_suffix_regex"};

    my $tm = new Minerl::TemplateManager(template_dir => $templateDir, template_suffix => $templateSuffix);
    my $pm = new Minerl::PageManager( page_dir => $pageDir, page_suffix_regex => $pageSuffixRegex); 

    my $pages = $pm->pages();
    foreach my $page (@$pages) {
        my $html = $tm->applyTemplate($page->header("layout"), $page->content, [$cfg->{"template"}, $page->headers, { posts => $pm->posts() }]);

        my $destFile = "$outputDir/" . $page->outputFilename();

        #say "output: $destFile";

        open my $fh, ">:utf8", $destFile or die "Failed to write to '$destFile' - $!";
        binmode($fh, ":utf8");
        print $fh $html;
        close $fh;
    }
}

sub _copyRawResources {
    my ($self) = @_;

    my $cfg = $self->{"cfg"};
    my $rawDir = $cfg->{"system"}->{"raw_dir"};
    
    # if there's nothing to copy
    return if !-d $rawDir;

    my $outputDir = $cfg->{"system"}->{"output_dir"};

    find( { wanted => sub {
        if ( -d $_ ) {
            s|$rawDir||; # strip the first directory
            make_path ("$outputDir/" . $_, { mode => 0755 });
        } elsif ( -f $_ ) {
            my $srcFile = $_;
            s|$rawDir||;
            my ($destFile) = "$outputDir/$_";
            copy ($srcFile, $destFile);
        }
    }, no_chdir => 1 }, ($rawDir) ); 
}

sub build {
    my ($self) = @_;

    $self->_generatePages();
    $self->_copyRawResources();
}

my $minerl = new Minerl( cfg_file => "minerl.cfg" ); 
$minerl->build();

1;

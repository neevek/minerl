use strict;
use warnings;
use 5.10.0;

package Minerl::PageManager;

use Minerl::BaseObject;
our @ISA = qw(Minerl::BaseObject);

use File::Basename;
use Minerl::Page;
use Minerl::Formatter::Markdown;
use Minerl::Formatter::Perl;

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    my $pageDir = $self->{"page_dir"};
    my $pageSuffixRegex = $self->{"page_suffix_regex"};

    $self->_initPages($pageDir, $pageSuffixRegex);
   
    return $self;
}

sub _initPages {
    my ($self, $pageDir, $pageSuffixRegex) = @_;

    my $pageArr = $self->{"pages"} = [];

    opendir my $openedDir, $pageDir or die "$pageDir: $!";;
    my @files = readdir $openedDir;
    foreach my $filename (@files) {
        next if $filename !~ /$pageSuffixRegex/;

        #print "found page file: $pageDir/$filename\n" if $self->{"DEBUG"};

        # basename without suffix
        my ($name) = basename($filename) =~ /([^.]+)/;
        my $page = new Minerl::Page( filename => "$pageDir/$filename", name => $name );

        die "$filename: layout is not specified." if !$page->header("layout");

        push @$pageArr, $page;
    }
    closedir($openedDir);

    $self->_formatPages($pageArr);
}

sub _formatPages {
    my ($self, $pageArr) = @_;

    foreach my $page (@$pageArr) {
        my $formats = $page->formats();
        map { $page->applyFormatter($self->_obtainFormatter($_)) } @$formats if $formats;
    }
}

sub _obtainFormatter {
    my ($self, $name) = @_;
    given ($name) {
        when("markdown") { return new Minerl::Formatter::Markdown() } 
        when("perl") { return new Minerl::Formatter::Perl() } 
    }
}

sub pages {
    my ($self) = @_;
    return $self->{"pages"};
}

1;

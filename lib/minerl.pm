use strict;
use warnings;
use 5.10.0;

package Minerl;

use Minerl::TemplateManager;
use Minerl::PageManager;

use File::Path qw(make_path);
use File::Find qw(find);

sub generate {
    my $tm = new Minerl::TemplateManager(template_suffix => ".html");
    my $pm = new Minerl::PageManager( page_dir => "./pages", page_suffix_regex => "\\.(?:md|markdown)\$"); 

    my $outputDir = "out/";
    make_path($outputDir, { mode => 0755 });

    my $pages = $pm->pages();
    foreach my $page (@$pages) {
        my $html = $tm->applyTemplate($page->header("layout"), $page->content, $page->headers);

        my $destFile = $outputDir . $page->outputFilename();

        open my $fh, ">:utf8", $destFile or die "Failed to write to '$destFile' - $!";
        binmode($fh, ":utf8");
        print $fh $html;
        close $fh;
    }


    _copyRawResources($outputDir);
    
}

sub _copyRawResources {
    my ($outputDir) = @_;
    my $rawDir = "raw/";
    return if !-d $rawDir;

    find( { wanted => \&process, no_chdir => 1 }, ($rawDir) ); 
    sub process {
        if ( -d $_ ) {
            s|$rawDir||;
            make_path ("$outputDir/" . $_, { mode => 0755 });
        } elsif ( -f $_ ) {
            #my $srcFile = $_;
            #s|$rawDir||;

            #open my $srcFh, "<", $srcFile die "Failed to open '$srcFile' - $!";

            #open my $dstFh, ">:utf8", "$outputDir/" . $_ die "Failed to write to '$_' - $!";
            #binmode($dstFh, ":utf8");
            #print $dstFh $html;
            #close $dstFh;
        }
    }
}

generate();

1;

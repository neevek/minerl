package main;
use strict;
use warnings;

our $VERSION = 0.01; 

use File::Path qw(make_path);
use Getopt::Compact::WithCmd;

my $go = Getopt::Compact::WithCmd->new(
    command_struct => {
       "build" => {
            options        => [[[qw(r rebuild)], qq(Rebuild all the pages), "!", undef, { default => 0}],
                               [[qw(v verbose)], qq(Print details), "!", undef, { default => 0 }]
                                ],
            args           => "[-r] [-v] [-h]",
            desc           => "- Applies the templates on the pages, generates the final HTML pages",
            other_usage    => ""
        },  
       "serve" => {
            options        => [[[qw(p port)], qq(The port which the HTTP server listens on), "=i", undef, { required => 1, default => 8888 }]],
            args           => "[-p port]",
            desc           => "- Starts an HTTP server to serve the directory specified by the 'output_dir' property in minerl.cfg",
            other_usage    => ""
        },  
       "createpost" => {
            options        => [[[qw(f filename)], qq(File name of the page), "=s", undef, { required => 1 }],
                               [[qw(l layout)], qq(Layout on which the newly created page is to be applied), "=s", undef, { required => 1 }],
                               [[qw(m format)], qq(Format of the page, currently supports 'html, markdown, perl'), ":s", undef, { required => 1, default => "html, markdown, perl" }],
                               [[qw(g tags)], qq(Tags for the post, separated by commas), ":s", undef, { required => 1, default => "uncategorized" }],
                               [[qw(t title)], qq(Title of the post), ":s", undef, { required => 1, default => "untitled" }],
                                ],
            args           => "<-f filename> <-l layout> [-m format] [-g tags] [-t title]",
            desc           => "- Creates the skeleton of a new post",
            other_usage    => ""
        },  
       "generate" => {
            options        => [[[qw(d dirname)], qq(The directory name to the site to be created), "=s", undef, { required => 1 }]],
            args           => "<-n dirname>",
            desc           => "- Creates a brand new Minerl site",
            other_usage    => ""
        },  
    },
    name => "minerl"
);


my $command = $go->command;
my $opts = $go->opts;
$go->show_usage if !$command;

if ($command eq 'generate') {
    my $dirname = $opts->{"dirname"};
    !-d $dirname or print "$dirname already exists\n" and exit 0;
    make_path($dirname, { mode => 0755 });
      
    make_path("$dirname/_templates", { mode => 0755 });
    make_path("$dirname/_pages", { mode => 0755 });
    make_path("$dirname/_raw", { mode => 0755 });

    createDefaultConfigurationFile("$dirname/minerl.cfg");
    createDefaultLayout("$dirname/_templates/default.html");
    createDefaultPage('default', "$dirname/_pages/index.html");
    
    exit 0;
}

my $minerl = new minerl( cfg_file => "minerl.cfg" ); 

if ($command eq 'build') {
    $minerl->build($opts->{"verbose"});
} elsif ($command eq 'serve') {
    use HTTP::Server::Brick;
    my $server = HTTP::Server::Brick->new( host => "localhost", port => $opts->{"port"});
    $server->mount("/" => {"path" => $minerl->{"cfg"}->{"system"}->{"output_dir"}});
    $server->start()
} elsif ($command eq 'createpost') {
    use POSIX qw(strftime);
    my $timestamp = time;
    my ($date) = strftime("%F %T", localtime $timestamp) =~ /([^ ]+) (.+)$/;

    my $filename = $opts->{"filename"};
    my $layout = $opts->{"layout"};
    my $format = $opts->{"format"};
    my $tags = $opts->{"tags"};
    my $title = $opts->{"title"};

    my $headers = "---\n"
    . "title: $title\n"
    . "layout: $layout\n"
    . "format: $format\n"
    . "type: post\n"
    . "tags: $tags\n"
    . "timestamp: $timestamp\n"
    . "---\n\n";

    my $pageDir = $minerl->{"cfg"}->{"system"}->{"page_dir"};
    my $pageSubDir = $date;
    $pageSubDir =~ s|-|/|g;
    make_path("$pageDir/$pageSubDir", { mode => 0755 });

    my $finalFilePath = "$pageDir/$pageSubDir/$filename";

    if (-f $finalFilePath) {
        print "$finalFilePath exists, override it? <y/n>\n";
        my $answer = <STDIN>;
        chomp $answer;
        if (lc $answer ne "y") {
            exit 0;  
        }
    }

    open my $fh, ">:utf8", $finalFilePath or die "Failed to write to '$finalFilePath' - $!";
    binmode($fh, ":utf8");
    print $fh $headers;
    close $fh;

    print "Created: $finalFilePath\n";
}

sub createDefaultConfigurationFile {
    my ($cfgFile) = @_;

    my $defaultConfigurations = <<CONFIG;
# system wide configurations go under the [system] section
[system]
# minerl will read files that end with 'template_suffix' in this
# directory as templates(Minerl::Template) to apply on the pages of the site
template_dir = _templates

# files that end with 'template_suffix' will be treated as 
# templates and will finally be used to construct HTML::Template objects,
template_suffix = .html

# minerl will read files that match 'page_suffix_regex' in this directory
# as pages(Minerl::Page), upon which minerl applies templates according
# to the 'layout' setting in the header section of the page
page_dir = _pages

# files that match 'page_suffix_regex' will be treated as 
# pages and will be processed by minerl to generate final HTML files
page_suffix_regex = \.(?:md|markdown|html)\$

# all generated files and resource files will be coplied to this directory
output_dir = site

# this directory contains files that minerl will copy to 'output_dir'
# without modification when you execute 'minerl build'.
# this directory is for storing image/js/css files.
raw_dir = _raw

# when generating data for the '__minerl_recent_posts' builtin variable, 
# minerl uses this setting to limit the number of entries
recent_posts_limit = 5

# configurations under [template] section will be made available to template
# files, namely, properties under [template] section can be referenced in template
# files
[template]
author = neevek
email = i at neevek.net
CONFIG
# END CONFIG

    open my $cfgFh, ">:utf8", $cfgFile;
    print $cfgFh $defaultConfigurations;
    close $cfgFh;
}

sub createDefaultLayout{ 
    my ($layoutFilename) = @_;

    my $content = <<HTML;
<!DOCTYPE HTML>
<html>
     <head>
         <meta http-equiv="content-type" content="text/html; charset=utf-8">
         <title><TMPL_VAR title></title>
     </head>
     <body>
         <TMPL_VAR content>
     </body>
</html>
HTML
# END HTML 

    open my $fh, ">:utf8", $layoutFilename;
    print $fh $content;
    close $fh;
}

sub createDefaultPage{ 
    my ($layout, $pageFilename) = @_;

    my $content = <<MARKDOWN;
---
title: Hello World
layout: ${layout}
format: markdown
slug: index.html
---
## Hello, World!
This is the first page generated by **Minerl**.
MARKDOWN
# END MARKDOWN 

    open my $fh, ">:utf8", $pageFilename;
    print $fh $content;
    close $fh;
}

1;

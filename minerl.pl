package main;
use strict;
use warnings;

our $VERSION = 0.01; 

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
                               [[qw(m format)], qq(Format of the page, currently supports 'markdown, perl'), ":s", undef, { required => 1, default => "markdown, perl" }],
                               [[qw(g tags)], qq(Tags for the post, separated by commas), ":s", undef, { required => 1, default => "uncategorized" }],
                               [[qw(t title)], qq(Title of the post), ":s", undef, { required => 1, default => "untitled" }],
                                ],
            args           => "<-f filename> <-l layout> [-m format] [-g tags] [-t title]",
            desc           => "- Creates the skeleton of a new post",
            other_usage    => ""
        },  
    },
    name => "minerl"
);


my $command = $go->command;
my $opts = $go->opts;
$go->show_usage if !$command;

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

1;

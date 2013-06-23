use strict;
use warnings;
use 5.10.0;

package Minerl::Util;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parsePageFile);

use File::Basename;

use constant {
    PAGE_PREREAD => 1,
    PAGE_READ_HEADER => 2,
    PAGE_READ_CONTENT => 3 
};

# this subroutine parses file that is composed of a 
# header section and content section
sub parsePageFile {
    my ($filename, $hash) = @_;

    $hash = $hash || {};
    my $content = "";
    my $state = PAGE_PREREAD;
    open FILE, "<:utf8", $filename;
    while (my $line = <FILE>) {

        if ($line =~ /^-{3,}$/) {
            if ($state == PAGE_PREREAD) {
                $state = PAGE_READ_HEADER;
                next; # ignore the dashed line
            }
            if ($state == PAGE_READ_HEADER) {
                $state = PAGE_READ_CONTENT;
                next; # ignore the dashed line
            }
        } elsif ($state == PAGE_PREREAD && $line !~ /^-{3,}$/) {
            $state = PAGE_READ_CONTENT;
        }

        given ($state) {
            when (PAGE_READ_HEADER)  {
                # strip leading white spaces
                $line =~ s/^[ \t]+//g;

                # skip comments
                next if $line =~ /^#/;

                # strip trailing white spaces
                $line =~ s/[ \t\n]+$//g;
                my ($key, $value) = split "[ \t]*:[ \t]*", $line;
                $hash->{"headers"}->{$key} = $value;
            }
            when (PAGE_READ_CONTENT) {
                $content .= $line; 
            }
        } 
    } 

    $hash->{"content"} = $content;

    die "$filename: Header section is not closed." if $state == PAGE_READ_HEADER;
    close(FILE);

    return $hash;
}

1;

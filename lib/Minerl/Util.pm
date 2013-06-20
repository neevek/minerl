use strict;
use warnings;
use 5.10.0;

package Minerl::Util;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parseFile);

use File::Basename;

use constant {
    PRE_READ => 1,
    READ_HEADER => 2,
    READ_CONTENT => 3 
};

# this subroutine parses file that is composed of a 
# header section and content section
sub parseFile {
    my ($filename, $hash) = @_;

    $hash = $hash || {};
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
                $hash->{"headers"}->{$key} = $value;
            }
            when (READ_CONTENT) {
                $content .= $line; 
            }
        } 
    } 

    $hash->{"content"} = $content;

    die "$filename: Header section is not closed." if $state == READ_HEADER;
    close(FILE);

    return $hash;
}

1;

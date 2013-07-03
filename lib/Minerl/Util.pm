=head1 NAME

Minerl::Util - Utility class

=head1 SYNOPSIS

    use Minerl::Util;
    my %hash;
    Minerl::Util::parsePageFile($filename, \%hash);
    ...

=head1 DESCRIPTION

This class includes some utility routines

=head1 AUTHOR

neevek, C<< <i at neevek.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 neevek.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=head1 SUBROUTINES/METHODS

=cut
package Minerl::Util;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(parsePageFile);
our @EXPORT_OK = qw(parsePageFile);

use File::Basename;

use constant {
    PAGE_PREREAD => 1,
    PAGE_READ_HEADER => 2,
    PAGE_READ_CONTENT => 3 
};

=head2 

this subroutine parses file that is composed of a header section and content section

=cut

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

        if ($state == PAGE_READ_HEADER) {
            # strip leading white spaces
            $line =~ s/^[ \t]+//g;

            # skip comments
            next if $line =~ /^#/;

            # strip trailing white spaces
            $line =~ s/[ \t\n]+$//g;
            my ($key, $value) = $line =~ '^([^:]+):[ \t]*(.*)$';
            $hash->{headers}->{$key} = $value;
        } elsif ($state == PAGE_READ_CONTENT) {
            $content .= $line; 
        }
    } 

    $hash->{content} = $content;

    die "$filename: Header section is not closed." if $state == PAGE_READ_HEADER;
    close(FILE);

    return $hash;
}

1;

=head1 NAME

Minerl::Page - A Page encapsulates a file, either a page or a template 

=cut

=head1 SYNOPSIS

    use Minerl::Page;
    my $page = new Minerl::Page( filename => "test.md", name => "test" );
    $page->headers();
    $page->content();
    $page->outputFilename();
    ...

=head1 DESCRIPTION

This class encapsulates a file, which contains a header section and a 
content section, the header section is surrounded with 3 or more dashes.

=head1 AUTHOR

neevek, C<< <i at neevek.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 neevek.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=head1 METHODS

=cut

package Minerl::Page;

our @ISA = qw(Minerl::BaseObject);

use File::Basename;

=head2 new

The contstructor takes a filename as parameter, and then it uses
C<Minerl::Util::parsePageFile> to parse the file, the headers and content
will be correctly set in the C<$self> HASH when the method returns.

=cut

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    my $filename = $self->{"filename"};

    die "Must pass in filename of the page." if !$filename;
    Minerl::Util::parsePageFile($filename, $self);
   
    return $self;
}

sub header {
    my ($self, $key) = @_;
    return $self->{"headers"}->{$key};
}

sub headers {
    my ($self) = @_;
    return $self->{"headers"};
}

=head2 content

Returns the content of the page, when C<$limit> is not empty, it is used
as a restriction to limit the number of characters to te returned

=cut

sub content {
    my ($self, $limit) = @_;
    if (!$limit) {
        return \$self->{"content"};
    } else {
        my $content = \$self->{"content"};
        if (length $$content > $limit) {
            return \substr($$content, 0, $limit);
        }
        return $content;
    }
}

=head2 applyFormatter

Applies the supplied formatter on the content, makes variables in the headers 
available to the formatter.

=cut

sub applyFormatter {
    my ($self, $formatter) = @_;
    $self->{"content"} = $formatter->format( \$self->{"content"}, $self->headers() );
}

=head2 formats

Gets all the formats that are specified by the C<format> field in the header

=cut

sub formats {
    my ($self) = @_;
    my $formatHeader = $self->header("format");

    return $formatHeader ? [split "[ \t]*,[ \t]*", $formatHeader] : undef;
}

=head2 ctxVars

C<ctx_vars> is a HASH that stores some context variables of the page, such as
C<__post_title>, C<__post_createdate> etc. these values are set in C<Minerl::PageManager>

=cut

sub ctxVars {
    my ($self, $ctxVars) = @_;
    $self->{"ctx_vars"} = $ctxVars if $ctxVars;
    return $self->{"ctx_vars"};
}

sub ctxVar {
    my ($self, $key) = @_;
    return $self->ctxVar($key);
}

=head2 outputFilename

Content of this page, after being applied a template, will be output to C<output_dir>
with this filename.

=cut

sub outputFilename {
    my ($self, $designatedName) = @_;

    my $outputFilename = $self->{"output_filename"};
    return $outputFilename if $outputFilename;

    $outputFilename = $self->{"filename"};

    # strip the first dirname, which is the root directory of
    # the page
    $outputFilename =~ s|^[^/]*/||g;    

    my $dir = dirname($outputFilename);

    if ($designatedName) {
        if ($dir) {
            return "$dir/$designatedName";
        } else {
            return $designatedName;
        }
    } else {
        my $slug = $self->header("slug");
        if ($slug && $dir ne ".") {
            $slug = "$dir/$slug";
        }
        return $slug if $slug;

        $outputFilename = lc $self->header("title");
        die "Post does not contain a title header: " . $self->{"filename"} if !$outputFilename;

        $outputFilename =~ s/[^a-z]/ /g;
        $outputFilename =~ s/^[ \t]+//g;         # trim left
        $outputFilename =~ s/[ \t]+$//g;         # trim right
        $outputFilename =~ s/[ \t]+/-/g;         # replace all whitespaces with dashes

        $outputFilename = $outputFilename . ".html";
        $outputFilename = "$dir/$outputFilename" if $dir ne ".";
    }

    return $self->{"output_filename"} = $outputFilename;
}

1;

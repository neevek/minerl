=head1 
    Page is an abstraction of the content of a file that
    is composed of a header section and a content section.
=cut

use strict;
use warnings;
use 5.10.0;

package Minerl::Page;

use Minerl::BaseObject;
our @ISA = qw(Minerl::BaseObject);

use Minerl::Util;

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

sub content {
    my ($self) = @_;
    return $self->{"content"};
}

sub applyFormatter {
    my ($self, $formatter) = @_;
    $self->{"content"} = $formatter->format( $self->{"content"}, $self->headers() );
}

sub formats {
    my ($self) = @_;
    my $formatHeader = $self->header("format");

    return $formatHeader ? [split "[ \t]*,[ \t]*", $formatHeader] : undef;
}

sub outputFilename {
    my ($self) = @_;

    my $slug = $self->header("slug");
    return $slug if $slug;

    $slug = lc $self->header("title");
    die "Post does not contain a title header: " . $self->{"filename"} if !$slug;

    $slug =~ s/[^a-z]/ /g;
    $slug =~ s/^[ \t]+//g;         # trim left
    $slug =~ s/[ \t]+$//g;         # trim right
    $slug =~ s/[ \t]+/-/g;         # replace all whitespaces with -

    return $slug . ".html";
}

1;

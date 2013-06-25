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
use File::Basename;

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    my $filename = $self->{"filename"};

    #say "new Page: $filename" if $self->{"DEBUG"};
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

sub applyFormatter {
    my ($self, $formatter) = @_;
    $self->{"content"} = $formatter->format( \$self->{"content"}, $self->headers() );
}

sub formats {
    my ($self) = @_;
    my $formatHeader = $self->header("format");

    return $formatHeader ? [split "[ \t]*,[ \t]*", $formatHeader] : undef;
}

sub ctxVars {
    my ($self, $ctxVars) = @_;
    $self->{"ctx_vars"} = $ctxVars if $ctxVars;
    return $self->{"ctx_vars"};
}

sub ctxVar {
    my ($self, $key) = @_;
    return $self->ctxVar($key);
}

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

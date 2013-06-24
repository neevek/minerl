use strict;
use warnings;
use 5.10.0;

package Minerl::PageManager;

use Minerl::BaseObject;
our @ISA = qw(Minerl::BaseObject);

use File::Basename;
use File::Find qw(find);
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
    my $postArr = $self->{"posts"} = [];

    die "$pageDir: Directory does not exist." if !-d $pageDir;

    my $taggedPosts = $self->{"tagged_posts"} = {};

    find( { wanted => sub {
        if ( -f $_ ) {
            return if $_ !~ /$pageSuffixRegex/;

            #print "found page file: $pageDir/$filename\n" if $self->{"DEBUG"};

            # basename without suffix
            my ($name) = basename($_) =~ /([^.]+)/;
            my $page = new Minerl::Page( filename => $_, name => $name );

            die "$_: 'layout' header is not specified." if !$page->header("layout");

            push @$pageArr, $page;

            my $pageType = $page->header("type");
            if ($pageType && $pageType eq "post") {
                my $post = {
                    title => $page->header("title"), 
                    createtime => $page->header("createtime"), 
                    link => "/" . $page->outputFilename(),
                }; 
                push @$postArr, $post;

                if ($page->header("tags")) {
                    my @tags = split /[ \t]*,[ \t]*/, $page->header("tags");
                    foreach my $t (@tags) {
                        next if !$t;

                        $t = lc $t;

                        my $postsByTag = $taggedPosts->{$t};
                        if (!$postsByTag) {
                            push @$postsByTag, $post;
                            $taggedPosts->{$t} = $postsByTag;
                        } else {
                            push @$postsByTag, $post;
                        }
                    }
                }
            }
        }
    }, no_chdir => 1 }, ($pageDir) ); 

    $self->_formatPages($pageArr);
}

sub _formatPages {
    my ($self, $pageArr) = @_;

    foreach my $page (@$pageArr) {
        my $formats = $page->formats();
        map { 
             my $formatter = $self->_obtainFormatter($_);
             $page->applyFormatter($formatter) if $formatter 
        } @$formats if $formats;
    }
}

sub _obtainFormatter {
    my ($self, $name) = @_;
    given ($name) {
        when("markdown") { return new Minerl::Formatter::Markdown() } 
        when("perl") { return new Minerl::Formatter::Perl() } 
        default { warn "formatter not supported: $name" }
    }
}

sub pages {
    my ($self) = @_;
    return $self->{"pages"};
}

sub posts {
    my ($self) = @_;
    return $self->{"posts"};
}

sub tags {
    my ($self) = @_;
    my $taggedPosts = $self->{"tagged_posts"};
    my @keys = keys %$taggedPosts if $taggedPosts;
    return \@keys;
}

sub postCountOfTag {
    my ($self, $tag) = @_;
    my $taggedPosts = $self->{"tagged_posts"};
    if ($taggedPosts) {
        my $count = @{$taggedPosts->{$tag}};
        return $count; 
    } else {
        return 0;
    }
}

sub getPostsByTag {
    my ($self, $tag) = @_;
    my $taggedPosts = $self->{"tagged_posts"};
    return $taggedPosts ? $taggedPosts->{$tag} : undef;
}

sub allTags {
    my ($self) = @_;
    my $taggedPosts = $self->{"tagged_posts"};

    my @allTags;
    while (my ($tag, $posts) = each %$taggedPosts) {
        my $count = @$posts;
        push @allTags, { tag => $tag, count => $count };    
    }

    @allTags = sort { $a->{"tag"} cmp $b->{"tag"} } @allTags;

    return \@allTags;
}

1;

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

use POSIX;

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
    my $archivedPosts = $self->{"archived_posts"} = {};

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
                    link => "/" . $page->outputFilename(),
                }; 
                $post->{"createtime"} = POSIX::strftime("%b %d, %Y %H:%M:%S", localtime($page->header("createtime")))
                    if $page->header("createtime");

                push @$postArr, $post;

                # categorize the posts by tags
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

                if ($page->header("createtime")) {
                    my $monthAsKey = POSIX::strftime("%Y/%m", localtime($page->header("createtime")));
                    my $postsByMonth = $archivedPosts->{$monthAsKey};
                    if (!$postsByMonth) {
                        push @$postsByMonth, $post;
                        $archivedPosts->{$monthAsKey} = $postsByMonth;
                    } else {
                        push @$postsByMonth, $post;
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

sub getPostsByTag {
    my ($self, $tag) = @_;
    my $taggedPosts = $self->{"tagged_posts"};
    return $taggedPosts ? $taggedPosts->{$tag} : undef;
}

sub postTags {
    my ($self) = @_;
    my $taggedPosts = $self->{"tagged_posts"};

    my @postTags;
    while (my ($tag, $posts) = each %$taggedPosts) {
        my $count = @$posts;
        push @postTags, { tag => $tag, count => $count };    
    }

    @postTags = sort { $a->{"tag"} cmp $b->{"tag"} } @postTags;

    return \@postTags;
}

# months during which some blog entries were created
sub months {
    my ($self) = @_;
    my $archivedPosts = $self->{"archived_posts"};
    my @keys = keys %$archivedPosts if $archivedPosts;
    return \@keys;
}

sub getPostsByMonth {
    my ($self, $month) = @_;
    my $archivedPosts = $self->{"archived_posts"};
    return $archivedPosts ? $archivedPosts->{$month} : undef;
}

# months during which some blog entries were created
sub postMonths {
    my ($self) = @_;
    my $archivedPosts = $self->{"archived_posts"};

    my @months;
    while (my ($month, $posts) = each %$archivedPosts) {
        my $count = @$posts;
        push @months, { month => $month, count => $count };    
    }

    @months = sort { $a->{"month"} cmp $b->{"month"} } @months;

    return \@months;
}

1;

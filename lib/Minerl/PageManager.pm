use strict;
use warnings;
use 5.10.0;

package Minerl::PageManager;

use Minerl::BaseObject;
our @ISA = qw(Minerl::BaseObject);

use File::Basename;
use File::Find qw(find);
use File::stat;
use POSIX;
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

    my @postArr;

    die "$pageDir: Directory does not exist." if !-d $pageDir;

    my $taggedPosts = $self->{"tagged_posts"} = {};
    my $archivedPosts = $self->{"archived_posts"} = {};

    # this hash is used to sort the date 
    my $archivedMonths = $self->{"archived_months"} = {};

    find( { wanted => sub {
        if ( -f $_ ) {
            return if $_ !~ /$pageSuffixRegex/;

            #print "found page file: $pageDir/$filename\n" if $self->{"DEBUG"};

            # basename without suffix
            my ($name) = basename($_) =~ /([^.]+)/;
            my $page = new Minerl::Page( filename => $_, name => $name );

            my $formats = $page->formats();
            map { 
                my $formatter = $self->_obtainFormatter($_);
                $page->applyFormatter($formatter) if $formatter 
            } @$formats if $formats;

            die "$_: 'layout' header is not specified." if !$page->header("layout");

            push @$pageArr, $page;

            my $pageType = $page->header("type");
            if ($pageType && $pageType eq "post") {

                my @postTags;

                my @tags;
                if ($page->header("tags")) {
                    @tags = split /[ \t]*,[ \t]*/, $page->header("tags");
                    @tags = grep { $_ } @tags;

                    foreach my $t (@tags) {
                        push @postTags, { name => $t, link => "/tags/$t.html" };
                    }
                }

                my $post = {
                    title => $page->header("title"), 
                    link => "/" . $page->outputFilename(),
                    content => ${$page->content()},
                    excerpt => ${$page->content(150)},
                }; 

                $page->{"headers"}->{"timestamp"} = stat($_)->ctime if !$page->header("timestamp");
                $post->{"timestamp"} = $page->header("timestamp");
                $post->{"createdate"} = POSIX::strftime("%b %d, %Y", localtime($page->header("timestamp")));
                $post->{"createtime"} = POSIX::strftime("%b %d, %Y %H:%M:%S", localtime($page->header("timestamp")));
                $page->{"headers"}->{"createtime"} = $post->{"createtime"};
                $page->{"headers"}->{"minerl_tags"} = \@postTags;

                push @postArr, $post;

                # categorize the posts by tags
                foreach my $t (@tags) {
                    $t = lc $t;

                    my $postsByTag = $taggedPosts->{$t};
                    if (!$postsByTag) {
                        push @$postsByTag, $post;
                        $taggedPosts->{$t} = $postsByTag;
                    } else {
                        push @$postsByTag, $post;
                    }
                }

                my $monthAsKey = POSIX::strftime("%b, %Y", localtime($page->header("timestamp")));
                $archivedMonths->{$monthAsKey} = POSIX::strftime("%Y/%m", localtime($page->header("timestamp")));
                my $postsByMonth = $archivedPosts->{$monthAsKey};
                if (!$postsByMonth) {
                    push @$postsByMonth, $post;
                    $archivedPosts->{$monthAsKey} = $postsByMonth;
                } else {
                    push @$postsByMonth, $post;
                }

            }
        }
    }, no_chdir => 1 }, ($pageDir) ); 

    @postArr = sort { $b->{"timestamp"} <=> $a->{"timestamp"} } @postArr;
    $self->{"posts"} = \@postArr;

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
    my ($self, $limit) = @_;
    if (!$limit) {
        return $self->{"posts"};
    } else {
        my $posts = $self->{"posts"}; 
        if (scalar @$posts > $limit) {
            my @slice = @$posts[0..$limit-1]; 
            return \@slice;
        }
        return $posts;
    }
}

sub tags {
    my ($self) = @_;
    my $taggedPosts = $self->{"tagged_posts"};
    my @keys = keys %$taggedPosts if $taggedPosts;
    return \@keys;
}

sub postsByTag {
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

sub monthLink {
    my ($self, $month) = @_;
    return $self->{"archived_months"}->{$month};
}

sub postsByMonth {
    my ($self, $month) = @_;
    my $archivedPosts = $self->{"archived_posts"};
    return $archivedPosts ? $archivedPosts->{$month} : undef;
}

# months during which some blog entries were created
sub postMonths {
    my ($self) = @_;
    my $archivedPosts = $self->{"archived_posts"};

    my $archivedMonths = $self->{"archived_months"};

    my @months;
    while (my ($month, $posts) = each %$archivedPosts) {
        my $count = @$posts;
        # format: "June, 2013", "2013/06", "12"
        push @months, { month_display => $month, month_link => $archivedMonths->{$month},  count => $count };    
    }

    @months = sort { $a->{"month_link"} cmp $b->{"month_link"} } @months;

    return \@months;
}

1;

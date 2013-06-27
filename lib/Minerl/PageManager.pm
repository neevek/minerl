=head1 NAME

Minerl::PageManager - Manages all pages under C<page_dir>

=head1 SYNOPSIS

    use Minerl::PageManager;
    my $pm = new Minerl::PageManager( page_dir => $pageDir, page_suffix_regex => $pageSuffixRegex); 
    $pm->pages();
    $pm->posts();
    ...

=head1 DESCRIPTION

This class manages all the pages in C<page_dir>, it processes all
the pages and prepares some of the builiin variables for template
files, such as C<__post_title>, C<__post_link>, etc.

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

package Minerl::PageManager;

our @ISA = qw(Minerl::BaseObject);

use File::Basename;
use File::Find qw(find);
use File::stat;
use POSIX;

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    my $pageDir = $self->{"page_dir"};
    my $pageSuffixRegex = $self->{"page_suffix_regex"};

    $self->_initPages($pageDir, $pageSuffixRegex);
   
    return $self;
}

=head2 _initPages

Searches C<page_dir> for files that match C<page_suffix_regex>, appplies
formatters on the content of the pages, prepares some builtin variables, 
which will be made available to template files.

=cut

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

            die "$_: 'layout' header is not specified." if !$page->header("layout");

            # applies formatters on all pages
            my $formats = $page->formats();
            map { 
                my $formatter = $self->_obtainFormatter($_);
                $page->applyFormatter($formatter) if $formatter 
            } @$formats if $formats;

            push @$pageArr, $page;

            my $pageType = $page->header("type");

            # only for pages of 'post' type do we need to extract some properties
            if ($pageType && $pageType eq "post") {
                my @postTags;

                my @tags;
                # if any tags were specified, extract them and put them in the array  
                if ($page->header("tags")) {
                    @tags = split /[ \t]*,[ \t]*/, $page->header("tags");
                    @tags = grep { $_ } @tags;

                    foreach my $t (@tags) {
                        push @postTags, { __minerl_tag_name => $t, __minerl_tag_link => "/tags/$t.html" };
                    }
                }

                # generates the create timestamp for the page if it is absent in the header 
                $page->{"headers"}->{"timestamp"} = stat($_)->ctime if !$page->header("timestamp");

                # setup builtin variables
                my $post= {
                    __post_timestamp => $page->header("timestamp"),   # this is for sorting
                    __post_title => $page->header("title"),
                    __post_link => "/" . $page->outputFilename(),
                    __post_createdate => POSIX::strftime("%b %d, %Y", localtime($page->header("timestamp"))),
                    __post_createtime => POSIX::strftime("%I:%M %p", localtime($page->header("timestamp"))),
                    __post_tags => \@postTags,
                    __post_content => ${$page->content()},
                    __post_excerpt => ${$page->content(150)},
                };

                # save these builtin variables in the context of the page
                $page->ctxVars($post);

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

                # group the posts by month
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

    # sort the posts by createtime
    @postArr = sort { $b->{"__post_timestamp"} <=> $a->{"__post_timestamp"} } @postArr;
    $self->{"posts"} = \@postArr;
}

=head2 _obtainFormatter

Obtains a formatter with a name

=cut

sub _obtainFormatter {
    my ($self, $name) = @_;
    my $formatterHash = $self->{"formatters"};
    if (!$formatterHash) {
        $formatterHash->{"markdown"} = new Minerl::Formatter::Markdown();
        $formatterHash->{"perl"} = new Minerl::Formatter::Perl();
    }

    if (defined $formatterHash->{$name}) {
        return $formatterHash->{$name};
    } else {
        warn "formatter not supported: $name" unless $name eq 'html';
    }
}

=head2 pages

Gets all pages of any type(specified in the header section of the page)

=cut

sub pages {
    my ($self) = @_;
    return $self->{"pages"};
}

=head2 posts

Gets an ARRAY of all or C<$limit> count of posts, each post is
a HASH, the HASH contains builtin variables of the post, which 
will be made available to template files.

=cut

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

=head2 tags

Gets an ARRAY of tags from all posts, the ARRAY contains builtin
variables of the page

=cut

sub tags {
    my ($self) = @_;
    my $taggedPosts = $self->{"tagged_posts"};
    my @keys = keys %$taggedPosts if $taggedPosts;
    return \@keys;
}

=head2 postsByTag

Gets all posts of the specified tag

=cut

sub postsByTag {
    my ($self, $tag) = @_;
    my $taggedPosts = $self->{"tagged_posts"};
    return $taggedPosts ? $taggedPosts->{$tag} : undef;
}

=head2 postTgas

Gets all tags of the posts

=cut

sub postTags {
    my ($self) = @_;
    my $taggedPosts = $self->{"tagged_posts"};

    my @postTags;
    while (my ($tag, $posts) = each %$taggedPosts) {
        my $count = @$posts;
        push @postTags, { __minerl_tag => $tag, __minerl_post_count => $count };    
    }

    @postTags = sort { $a->{"__minerl_tag"} cmp $b->{"__minerl_tag"} } @postTags;

    return \@postTags;
}

=head2 months

months during which some posts were created

=cut

sub months {
    my ($self) = @_;
    my $archivedPosts = $self->{"archived_posts"};
    my @keys = keys %$archivedPosts if $archivedPosts;
    return \@keys;
}

=head2 monthLink

    my $month = $self->monthLink("2013/06");
    $month eq "Jun, 2013";

=cut

sub monthLink {
    my ($self, $month) = @_;
    return $self->{"archived_months"}->{$month};
}

=head2 postsByMonth

Gets all posts created on the specified month

=cut

sub postsByMonth {
    my ($self, $month) = @_;
    my $archivedPosts = $self->{"archived_posts"};
    return $archivedPosts ? $archivedPosts->{$month} : undef;
}

=head2 postsMonths

months during which some posts were created

=cut

sub postMonths {
    my ($self) = @_;
    my $archivedPosts = $self->{"archived_posts"};

    my $archivedMonths = $self->{"archived_months"};

    my @months;
    while (my ($month, $posts) = each %$archivedPosts) {
        my $count = @$posts;
        # format: "June, 2013", "2013/06", "12"
        push @months, { __minerl_month_display => $month, __minerl_month_link => $archivedMonths->{$month},  __minerl_post_count => $count };    
    }

    @months = sort { $a->{"__minerl_month_link"} cmp $b->{"__minerl_month_link"} } @months;

    return \@months;
}

1;

=head1 NAME

minerl - A static site generator written in Perl

=head1 VERSION

our $VERSION = '0.01';

=head1 SYNOPSIS

    use minerl;
    my $minerl = new minerl( cfg_file => "minerl.cfg" ); 
    minerl->build();
    ...

=head1 DESCRIPTION

This class exposes only one public method - build(), which is used to generate
pages of the site and copy all raw resources to the output directory.

=head1 AUTHOR

neevek, C<< <i at neevek.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 neevek.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

package minerl;
use encoding "utf-8";

our $VERSION = '0.01';

our @ISA = qw(Minerl::BaseObject);

use Config::IniFiles;
use File::Path qw(make_path);
use File::Find qw(find);
use File::Copy qw(copy); 
use File::Basename qw(dirname); 

=head1 SUBROUTINES/METHODS

=head2 new 

The constructor, which calls C<$self->_initConfigFile()> to read configurations
from the cfg file, usually C<minerl.cfg>

=cut

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    $self->_initConfigFile();

    return $self;
}

=head2 _initConfigFile

For internal use only, it uses C<Config::IniFiles> to read the configurations
and setup defaults for properties that are absent in the configuration file

=cut

sub _initConfigFile {
    my ($self) = @_;

    my $cfgFile = $self->{"cfg_file"};
    -f $cfgFile or die "$cfgFile not found.";

    tie my %cfg, 'Config::IniFiles', ( -file => $cfgFile );

    $cfg{"system"} = {} if !$cfg{"system"};
    foreach my $k (keys %{$cfg{"system"}}) {
        $cfg{"system"}->{$k} =~ s/[\t\s]+$//;  
    }

    $cfg{"system"}->{"output_dir"} = "site" if !$cfg{"system"}->{"output_dir"};
    $cfg{"system"}->{"raw_dir"} = "_raw" if !$cfg{"system"}->{"raw_dir"};
    $cfg{"system"}->{"page_dir"} = "_pages" if !$cfg{"system"}->{"page_dir"};
    $cfg{"system"}->{"page_suffix_regex"} = "\\.(?:md|markdown|html)\$" if !$cfg{"system"}->{"page_suffix_regex"};
    $cfg{"system"}->{"template_dir"} = "_templates" if !$cfg{"system"}->{"template_dir"};
    $cfg{"system"}->{"template_suffix"} = ".html" if !$cfg{"system"}->{"template_suffix"};
    $cfg{"system"}->{"recent_posts_limit"} = 5 if !$cfg{"system"}->{"recent_posts_limit"};

    $cfg{"template"} = {} if !$cfg{"template"};
    foreach my $k (keys %{$cfg{"template"}}) {
        $cfg{"template"}->{$k} =~ s/[\t\s]+$//;  
    }

    $self->{"cfg"} = \%cfg;
}

=head2 _generatePages

The main routine that generates all the HTML pages of the site, it reads all
files that match the specified suffix regex in C<page_dir>, applies the specified
templates on the pages, writes the final files to C<output_dir>.

=cut

sub _generatePages {
    my ($self, $verbose) = @_;

    my $cfg = $self->{"cfg"};
    my $pageDir = $cfg->{"system"}->{"page_dir"};
    -d $pageDir or die "$pageDir does not exist.";

    my $templateDir = $cfg->{"system"}->{"template_dir"};
    -d $templateDir or die "$templateDir does not exist.";

    # ensures the output_dir exists
    my $outputDir = $cfg->{"system"}->{"output_dir"};
    $outputDir =~ s/^[ \t]+//;
    $outputDir =~ s/[ \t]+$//;
    make_path($outputDir, { mode => 0755 });

    my $templateSuffix = $cfg->{"system"}->{"template_suffix"};
    my $pageSuffixRegex = $cfg->{"system"}->{"page_suffix_regex"};

    my $tm = new Minerl::TemplateManager(template_dir => $templateDir, template_suffix => $templateSuffix);
    my $pm = new Minerl::PageManager( page_dir => $pageDir, page_suffix_regex => $pageSuffixRegex); 

    # gets all the tags
    my $postTags = $pm->postTags();
    # gets all the archive months
    my $postMonths = $pm->postMonths();

    # gets all the pages
    my $pages = $pm->pages();
    foreach my $page (@$pages) {
        print "processing page: $page->{filename}\n" if $verbose;

        my $type = $page->header("type");
        if ($type && $type eq "taglist") { # if the page type is 'taglist', we loop through all the tags to generate page for each tag
            my $tags = $pm->tags();
            foreach my $tag (@$tags) {

                # gets all posts with the specified tag
                my $postsByTag = $pm->postsByTag($tag); 

                my $html = $tm->applyTemplate($page->header("layout"), $page->content
                    , [$cfg->{"template"}, $page->headers, { __minerl_all_posts => $pm->posts()
                    , __minerl_recent_posts => $pm->posts($cfg->{"system"}->{"recent_posts_limit"})
                    , __minerl_tagged_posts => $postsByTag , __minerl_cur_tag => $tag, "__minerl_all_tags" => $postTags, "__minerl_archived_months" => $postMonths } ]);

                # Pages of 'taglist' type are restricted to be output to "$output_dir/tags/"
                my $destFile = "$outputDir/tags/$tag.html";
                $self->_writePageFile($outputDir, $destFile, $html);

                print "  generated tag page: $destFile\n" if $verbose;
            } 
        } elsif ($type && $type eq "archive") { # if the page type is 'archive', we loop through all the archive months to generate page for each archive month 
            my $months = $pm->months();
            foreach my $month (@$months) {

                # gets all posts posted on the specified month
                my $postsByMonth = $pm->postsByMonth($month); 

                my $html = $tm->applyTemplate($page->header("layout"), $page->content
                    , [$cfg->{"template"}, $page->headers, { __minerl_all_posts => $pm->posts()
                    , __minerl_recent_posts => $pm->posts($cfg->{"system"}->{"recent_posts_limit"})
                    , __minerl_archived_posts => $postsByMonth, __minerl_cur_month => $month, "__minerl_all_tags" => $postTags, "__minerl_archived_months" => $postMonths } ]);

                # Pages of 'archive' type are restricted to be output to "$output_dir/archives/"
                my $destFile = "$outputDir/archives/" . $pm->monthLink($month) . ".html";
                $self->_writePageFile($outputDir, $destFile, $html);

                print "  generated archive page: $destFile\n" if $verbose;
            } 
        } else { # when the 'type' is not specified or is 'post', we treat it as normal page
            my $html = $tm->applyTemplate($page->header("layout"), $page->content, [$cfg->{"template"}, $page->headers, $page->ctxVars,
                    , { __minerl_all_posts => $pm->posts(), __minerl_recent_posts => $pm->posts($cfg->{"system"}->{"recent_posts_limit"})
                    , "__minerl_all_tags" => $postTags, "__minerl_archived_months" => $postMonths } ]);

            # outputFilename is affected by the title or the slug of the page specified at the header section
            # it has nothing to do with what filename is used for the source page
            my $destFile = "$outputDir/" . $page->outputFilename();
            $self->_writePageFile($outputDir, $destFile, $html);

            print "  generated normal page: $destFile\n" if $verbose;
        }
    }
}

=head2 _writePageFile

Reusable method that outputs a file to C<output_dir>

=cut

sub _writePageFile {
    my ($self, $outputDir, $destFile, $html) = @_;

    my $outputSubDir = dirname($destFile);
    make_path($outputSubDir, { mode => 0755 }) if !-d $outputSubDir;

    open my $fh, ">:utf8", $destFile or die "Failed to write to '$destFile' - $!";
    binmode($fh, ":utf8");
    print $fh $$html;
    close $fh;
}

=head2 _copyRawResources

Copies verbatim all files under C<raw_dir> to C<output_dir>.

=cut

sub _copyRawResources {
    my ($self, $verbose) = @_;

    my $cfg = $self->{"cfg"};
    my $rawDir = $cfg->{"system"}->{"raw_dir"};
    
    # if there's nothing to copy
    return if !-d $rawDir;

    my $outputDir = $cfg->{"system"}->{"output_dir"};

    find( { wanted => sub {
        if ( -d $_ ) {
            s|$rawDir||; # strip the first directory
            make_path ("$outputDir/" . $_, { mode => 0755 });
        } elsif ( -f $_ ) {
            my $srcFile = $_;
            s|$rawDir|$outputDir|; # replace 'raw_dir' with 'output_dir'
            copy ($srcFile, $_);
            
            print "  copied $srcFile to $_\n" if $verbose;
        }
    }, no_chdir => 1 }, ($rawDir) ); 
}

=head2 build

Public method that builds the site, it simply does two things:
generates HTML pages and copies static resources to C<output_dir>

=cut

sub build {
    my ($self, $verbose) = @_;

    $self->_generatePages($verbose);
    $self->_copyRawResources($verbose);
}

1;

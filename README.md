minerl
======

**Minerl** is a blog-aware static site generator written in Perl, it supports *tagging*, *automatic archiving*, *post*, *page*, *layout inheritance*.

Installation
============

Before installation, make sure you have all modules required by **Minerl** installed, **Minerl** depends on the following modules:

    Config::IniFiles
    HTML::Template
    Text::Template
    Text::MultiMarkdown
    Getopt::Compact::WithCmd
    HTTP::Server::Brick

I recommend [cpanm](https://raw.github.com/miyagawa/cpanminus/master/cpanm) for installing modules.

    curl -o cpanm https://raw.github.com/miyagawa/cpanminus/master/cpanm
    chmod +x cpanm

After cpanm is installed, use the following command to install all required modules, note you may need root permission if your Perl modules are installed in system directory:

    cpanm Config::IniFiles HTML::Template Text::Template \
        Text::MultiMarkdown Getopt::Compact::WithCmd HTTP::Server::Brick

Okay, all prerequisites are met, we are ready to install and try out **Minerl**. It is that straightforward, simply clone the code from github, change direcotry to the root of the project, `make && make install` installs the **minerl** script under `/usr/local/bin`:

    git clone https://github.com/neevek/minerl.git
    cd minerl
    make && make install

Now generate your first minerl site:

    minerl genearte -d mysite
    cd mysite
    minerl build -v
    minerl serve

You may have already seen the output of the commands, navigate your browser to `http://127.0.0.1:8888`. Cool! You have just created the first page of your minerl site.

Structure
=========

    mysite/
    ├── _pages
    │   └── index.html
    ├── _raw
    ├── _templates
    │   └── default.html
    └── minerl.cfg

Page files are put in the `_pages` directory, layout files are put in the `_templates` directory, resource files(images/js/css) are put in the `_raw` directory, these directories are all specified in the `minerl.cfg` configuration file.

Implemented Commands
====================

    minerl v0.01
    usage: minerl [options] COMMAND

    options:
       -h, --help      This help message

    Implemented commands are:
       build        - Applies the templates on the pages, generates the final HTML pages                               
       createpost   - Creates the skeleton of a new post                                                               
       generate     - Creates a brand new Minerl site                                                                  
       serve        - Starts an HTTP server to serve the directory specified by the 'output_dir' property in minerl.cfg

    See 'minerl help COMMAND' for more information on a specific command.

Currently 4 commands are implemented, for more information, run `minerl help COMMAND`.

What can Minerl do for you
==========================

Now that you have installed **minerl**, you may want to know more about it, and see what it can do for you. In the begining I mentioned that **Minerl** supports *tagging* and *automatic archiving*, which sounds unclear, what is that? 

**tagging** per se is not interesting at all, the fun part is that after you tag your blog posts, **Minerl** will organize all your posts and group them by tags, so that you can create index pages listing posts for each tag, which is cool for a pure static site. **automatic archiving** works in the same way, it organizes all your posts and group them by months, you can create index pages for all months as you would for tags. **automatic archiving** requires the *timestamp* header in every post to work. I recommend you always use `minerl createpost` to create the skeleton of a new post, which sets the *timestamp* as well as a few other headers for you.

Note: when I am talking about **posts**, I mean pages of type **post**, which is set in the header section.

Templates
=========

A template file is composed of a header section and a content/body section, header section starts and ends with 3 or more dashes. Minerl uses `HTML::Template` to expand variables in template files, template files can be inherited, which makes HTML structure design a lot easier even if you have many pages. A template inherits another by specifying the `layout` header and name the inherited template without suffix, like this:
 
    ---
    layout: default
    ---

### Caveats


- When a template is designed to be inherited(like `default.html` in the demo created by `minerl generate`), it MUST contain a variable called `content`, like this: `<TMPL_VAR content>`.

Pages
=====

Format of pages are the same as that of template files, a header section and a content/body section, the only difference is that you may always need to set more headers for pages. Let's take an example of this post, which contains the following headers:

- title: Introduction to Minerl
- layout: post
- format: markdown
- type: post
- tags: minerl, perl
- slug: introduction-to-minerl.html
- timestamp: 1372332934

For a normal page, the `type`, `tags` and `timestamp` headers are not needed. `slug` is used as the final output file name of the page, if it is absent, `title` will be used instead with whitespaces replaced with dahses.

Builtin variables
=================

**Minerl** offers quite a few builtin variables that can be used to generate index pages of tags and archives. Builtin variables can be referenced in templates with [HTML::Template](http://search.cpan.org/~wonko/HTML-Template-2.94/lib/HTML/Template.pm) syntax.

**Minerl** offers the following variables:

- `__minerl_all_posts`          - ARRAY, used in LOOP, available in all templates
- `__minerl_recent_posts`       - ARRAY, used in LOOP, available in all templates
- `__minerl_archived_months`    - ARRAY, used in LOOP, available in all templates
- `__minerl_archived_posts`     - ARRAY, used in LOOP, available in templates applied on pages of type `archive` 
- `__minerl_cur_month`          - string SCALAR, available in templates applied on pages of type `archive` 
- `__minerl_all_tags`           - ARRAY, used in LOOP, available in all templates
- `__minerl_tagged_posts`       - ARRAY, used in LOOP, available in templates applied on pages of type `taglist` 
- `__minerl_cur_tag`            - string SCALAR, available in templates applied on pages of type `taglist` 

The following builtin variables(string SCALAR) are only available in templates applied on pages of type `post`:

- `__post_timestamp`
- `__post_title`
- `__post_link`
- `__post_createdate`
- `__post_createtime`
- `__post_tags`
- `__post_content`
- `__post_exerpt`

Besides the above variables, all user defined variables in page headers are available to all templates. 

### Examples

The following code use the `__minerl_all_posts` variable to list all posts of the site:

    <ul>
        <TMPL_LOOP __minerl_all_posts>
            <li><a href="<TMPL_VAR __post_link>"><TMPL_VAR __post_title></a></li>
            <div class="post_content">
                <TMPL_VAR __post_excerpt>... 
            </div>
        </TMPL_LOOP>
    </ul>

The following code use the `__minerl_tagged_posts` variable to list all posts of a certain tag:

    <ul>
        <TMPL_LOOP __minerl_tagged_posts>
            <li><a href="<TMPL_VAR __post_link>"><TMPL_VAR __post_title></a></li>
            <div class="post_content">
                <TMPL_VAR __post_excerpt>... 
            </div>
        </TMPL_LOOP>
    </ul>

Formats
=======

Currently **Minerl** supports [markdown](http://search.cpan.org/~bobtfish/Text-MultiMarkdown-1.000034/lib/Text/MultiMarkdown.pm) and Perl script.

LICENSE AND COPYRIGHT
=====================

Copyright 2013 neevek.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0)

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

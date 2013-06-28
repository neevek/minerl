---
title: Introduction to Minerl
layout: post
format: markdown
type: post
tags: minerl, perl
timestamp: 1372332934
---

## Introduction

[Minerl](https://github.com/neevek/minerl) is a blog-aware static site generator written in Perl, it supports *tagging*, *automatic archiving*, *post*, *page*, *layout inheritance*.

## Installation

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

## Implemented Commands

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

## What can Minerl do for you

Now that you have installed **minerl**, you may want to know more about it, and see what it can do for you. In the begining I mentioned that **Minerl** supports *tagging* and *automatic archiving*, which sounds unclear, what is that? 

**tagging** per se is not interesting at all, the fun part is that after you tag your blog posts, **Minerl** will organize all your posts and group them by tags, so that you can create index pages listing posts for each tag, which is cool for a pure static site. **automatic archiving** works in the same way, it organizes all your posts and group them by months, you can create index pages for all months as you would for tags. **automatic archiving** requires the *timestamp* header in every post to work. I recommend you always use `minerl createpost` to create the skeleton of a new post, which sets the *timestamp* as well as a few other headers for you.

Note: when I am talking about **posts**, I mean pages of type **post**, which is set in the header section.

## Templates

A template file is composed of a header section and a content/body section, header section starts and ends with 3 or more dashes. Minerl uses `HTML::Template` to expand variables in template files, template files can be inherited, which makes HTML structure design a lot easier even if you have many pages. A template inherits another by specifying the `layout` header and name the inherited template without suffix, like this:
 
    ---
    layout: default
    ---

### Caveats

- When a template is designed to be inherited(like `default.html` in the demo created by `minerl generate`), it MUST contain a variable called `content`, like this: `<TMPL_VAR content>`.

## Pages

Format of pages are the same as that of template files, a header section and a content/body section, the only difference is that you may always need to set more headers for pages. Let's take an example of this post, which contains the following headers:

- title: Introduction to Minerl
- layout: post
- format: markdown
- type: post
- tags: minerl, perl
- slug: introduction-to-minerl.html
- timestamp: 1372332934

For a normal page, the `type`, `tags` and `timestamp` headers are not needed. `slug` is used as the final output file name of the page, if it is absent, `title` will be used instead with whitespaces replaced with dahses.

## Builtin variables

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

The following code uses the `__minerl_all_posts` variable to list all posts of the site:

    <ul>
        <TMPL_LOOP __minerl_all_posts>
            <li><a href="<TMPL_VAR __post_link>"><TMPL_VAR __post_title></a></li>
            <div class="post_content">
                <TMPL_VAR __post_excerpt>... 
            </div>
        </TMPL_LOOP>
    </ul>

The following code uses the `__minerl_tagged_posts` variable to list all posts of a certain tag:

    <ul>
        <TMPL_LOOP __minerl_tagged_posts>
            <li><a href="<TMPL_VAR __post_link>"><TMPL_VAR __post_title></a></li>
            <div class="post_content">
                <TMPL_VAR __post_excerpt>... 
            </div>
        </TMPL_LOOP>
    </ul>

## Formats

Currently **Minerl** supports [markdown](http://search.cpan.org/~bobtfish/Text-MultiMarkdown-1.000034/lib/Text/MultiMarkdown.pm) and Perl script, you can write your pages using markdown, like the one I am writing and embed some perl scripts in the page.

Okay, that is almost all about the first release of **Minerl**. Enjoy!

For more information, please run `minerl -h`.


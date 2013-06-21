---
layout: post
title: Today is a special day
format: perl, markdown
type: post
---

## {{ $title }}

---
Yes, this is the second page. let copy something here.

Starting from Perl 5.10.1 (well, 5.10.0, but it didn't work right), you can say
    use feature "switch";
to enable an experimental switch feature. This is loosely based on an old version of a Perl 6 proposal, but it no longer resembles the Perl 6 construct. You also get the switch feature whenever you declare that your code prefers to run under a version of Perl that is 5.10 or later. For example:
    use v5.14;
Under the "switch" feature, Perl gains the experimental keywords given , when , default , continue, and break . Starting from Perl 5.16, one can prefix the switch keywords with CORE:: to access the feature without a use feature statement. The keywords given and when are analogous to switch and case in other languages, so the code in the previous section could be rewritten as
    use v5.10.1;
    for ($var) {
    when (/^abc/) { $abc = 1 }
    when (/^def/) { $def = 1 }
    when (/^xyz/) { $xyz = 1 }
    default       { $nothing = 1 }
    }
The foreach is the non-experimental way to set a topicalizer. If you wish to use the highly experimental given , that could be written like this:


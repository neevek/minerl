use strict;
use warnings;

sub testDependencies {
    my @dependencies = qw(
        File::Path
        File::Copy
        File::Basename
        File::Find
        Config::IniFiles
        HTML::Template
        Text::Template
        Text::MultiMarkdown
        Getopt::Compact::WithCmd
        HTTP::Server::Brick
    );

    my @modules_not_installed;
    for my $module (@dependencies) {
        eval("use $module;");
        push @modules_not_installed, $module if $@;
    }

    my $install_cmd = "cpanm ";
    for my $module (@modules_not_installed) {
        print "warning: required module '$module' is not installed.\n";
        $install_cmd .= ($module . " ");
    }
    print "You may use cpanm to install the modules:\n'$install_cmd'\n\n" and exit 1 if @modules_not_installed;
}

testDependencies;

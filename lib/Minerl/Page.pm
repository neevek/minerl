use strict;
use warnings;
use 5.10.0;

package Minerl::Page;

use Minerl::BaseObject;
our @ISA = qw(Minerl::BaseObject);

use Minerl::Util;

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    my $filename = $self->{"filename"};
    die "Must pass in filename of the page." if !$filename;

   
    return $self;
}

1;

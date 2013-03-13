#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    unshift( @INC, "../" );
}

use iControl;
use iControl::Management::DBVariable;

my $name  = $ARGV[0];
my $value = $ARGV[1];

my $db = iControl::Management::DBVariable->new(
    protocol => 'https',
    host     => '10.3.72.33',
    username => 'admin',
    password => 'admin',
);

if (  defined $name  and ! defined $value) {
    my $result = $db->query($name);
    print "$name:\t$result\n";
}
elsif ( defined $name and defined $value ) {
    if ($value eq "reset") {
       $db->reset($name);
    }else {
      $db->modify( $name, $value );
      my $result = $db->query($name);
      print "$name:\t$result\n";
   }
}
else {
    list();
}

sub list {
    my @dbs = $db->get_list();
    foreach my $dbkey (@dbs) {
        my $name  = $dbkey->{name};
        my $value = $dbkey->{value};
	print "$name:$value\n";
    }
}


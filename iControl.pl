#!/usr/bin/perl
use strict;
use warnings;

use iControl;
use iControl::Networking::SelfIP;
use iControl::Networking::VLAN;
use iControl::Management::DBVariable;

#iControl OO module testing


my $selfip = iControl::Networking::SelfIP->new(protocol => 'https',
                                   host => '172.24.100.119',
                                   username => 'admin',
                                   password => 'admin');

my $db = iControl::Networking::DBVariable->new(protocol => 'https',
                                   host => '172.24.100.119',
                                   username => 'admin',
                                   password => 'admin');

my $unitid = $db->get_db_variable('Failover.UnitId');
print "unit id $unitid\n";

#$selfip->set_self_ipv2("selfiptest", "esnet-1102", "10.2.72.3", "255.255.0.0", 0);
$selfip->set_self_ip("10.2.72.3", "internal", "255.255.0.0", 2, 0);

my @selfips = $selfip->get_self_ips();

print "$_\n" for @selfips;

my $vlan = iControl::Networking::VLAN->new(protocol => 'https',
                                   host => '172.24.100.119',
                                   username => 'admin',
                                   password => 'admin');

my @vlans = $vlan->get_vlans();

print "$_\n" for @vlans;

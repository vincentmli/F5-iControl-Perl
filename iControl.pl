#!/usr/bin/perl
use strict;
use warnings;

use iControl;
use iControl::Networking::SelfIP;
use iControl::Networking::VLAN;
use iControl::Management::DBVariable;

#iControl OO module testing


my $selfip = iControl::Networking::SelfIP->new(protocol => 'https',
                                   host => '10.3.72.33',
                                   username => 'admin',
                                   password => 'admin',
                                   floating_states => 'STATE_ENABLED',
				   traffic_groups => 'traffic-group-1',
);

my $db = iControl::Management::DBVariable->new(protocol => 'https',
                                   host => '10.3.72.33',
                                   username => 'admin',
                                   password => 'admin',
);

my $unitid = $db->get_db_variable('Failover.UnitId');
print "unit id $unitid\n";

$selfip->delete_self_ip("10.2.72.35");
#$selfip->delete_self_ip("selfiptest");
#$selfip->set_self_ipv2("selfiptest", "int-esnet", "10.2.72.35", "255.255.0.0", 0);
$selfip->set_self_ipv2("selfiptest", "int-esnet", "10.2.72.35", "255.255.0.0");
#$selfip->set_self_ip("10.2.72.35", "int-esnet", "255.255.0.0", $unitid);
#$selfip->set_self_ip("10.2.72.35", "int-esnet", "255.255.0.0");
#$selfip->delete_self_ip("10.2.72.35");
$selfip->add_allow_access_list("10.2.72.35");
#$selfip->add_allow_access_listv2("selfiptest");

my @selfips = $selfip->get_self_ips();

print "$_\n" for @selfips;


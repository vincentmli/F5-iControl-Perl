#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
        unshift( @INC, "../" );
}

use iControl;
use iControl::Networking::SelfIP;
use iControl::Networking::SelfIPPortLockdown;
use iControl::Networking::SelfIPV2;
use iControl::Networking::VLAN;
use iControl::Management::DBVariable;
use iControl::Management::KeyCertificate;
use iControl::LocalLB::ProfileClientSSL;

#iControl OO module testing


my $selfipv2 = iControl::Networking::SelfIPV2->new(protocol => 'https',
                                   host => '10.3.72.33',
                                   username => 'admin',
                                   password => 'admin',
                                #   floating_states => 'STATE_ENABLED',
				#   traffic_groups => 'traffic-group-1',
);

my $selfip = iControl::Networking::SelfIP->new(protocol => 'https',
                                   host => '10.3.72.33',
                                   username => 'admin',
                                   password => 'admin',
#                                   floating_states => 'STATE_ENABLED',
);

my $db = iControl::Management::DBVariable->new(protocol => 'https',
                                   host => '10.3.72.33',
                                   username => 'admin',
                                   password => 'admin',
);

my $portlock = iControl::Networking::SelfIPPortLockdown->new(protocol => 'https',
                                   host => '10.3.72.33',
                                   username => 'admin',
                                   password => 'admin',
);

my $vlan = iControl::Networking::VLAN->new(protocol => 'https',
                                   host => '172.24.12.46',
                                   username => 'admin',
                                   password => 'admin',
				   member_type => 'MEMBER_TRUNK',
				   tag_state => 'MEMBER_UNTAGGED',
);

my $keycert = iControl::Management::KeyCertificate->new(protocol => 'https',
                                   host => '10.3.72.34',
                                   username => 'admin',
                                   password => 'admin',
);

my $profile = iControl::LocalLB::ProfileClientSSL->new(protocol => 'https',
                                   host => '10.3.72.34',
                                   username => 'admin',
                                   password => 'admin',
);

my $unitid = $db->get_db_variable('Failover.UnitId');
print "unit id $unitid\n";

#$selfip->delete_self_ip("10.2.72.35");
#$selfipv2->delete_self_ip("10.2.72.35");
#$selfipv2->create("10.2.72.35", "int-esnet", "10.2.72.35", "255.255.0.0");
#$selfip->set_floating_states('floating_states', 'STATE_ENABLED');
#$selfip->create("10.2.72.35", "int-esnet", "255.255.0.0");
#$selfip->delete_self_ip("10.2.72.35");
#$portlock->add_allow_access_list("10.2.72.35");
#$selfipv2->add_allow_access_list("10.2.72.35");

#my @selfips = $selfipv2->get_list();
#my @selfips = $selfip->get_list();
#print "$_\n" for @selfips;
#$vlan->delete_vlan("test");
#$vlan->create("test", "169", "trunk_test");
#my @timeout = $vlan->get_failsafe_timeout("test3");
#print "$_\n" for @timeout;
#my @vlans = $vlan->get_list;
#print "$_\n" for @vlans;

my $cert = '/home/vincent/vli_self_server.crt';
my $vli_self_cert_pem_data = do {
    local $/ = undef;
    open my $fh, "<", $cert
        or die "could not open $cert: $!";
    <$fh>;
};


my $key = '/home/vincent/vli_self_server.key';
my $vli_self_key_pem_data = do {
    local $/ = undef;
    open my $fh, "<", $key
        or die "could not open $key: $!";
    <$fh>;
};

$profile->delete_profile('vli_self_server_clientssl');
$keycert->key_delete("vli_self_server_key");
$keycert->certificate_delete("vli_self_server_cert");
$keycert->certificate_import_from_pem("vli_self_server_cert", $vli_self_cert_pem_data);
$keycert->key_import_from_pem("vli_self_server_key", $vli_self_key_pem_data);
$keycert->certificate_bind("vli_self_server_cert", "vli_self_server_key");
$profile->create_v2('vli_self_server_clientssl', "vli_self_server_key", "vli_self_server_cert");

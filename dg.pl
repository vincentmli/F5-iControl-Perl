#!/usr/bin/perl

#iControl device group configuration script Vincent v.li@f5.com, 2013-02-21

use strict;

use warnings;
use Getopt::Long;

#use SOAP::Lite + trace => qw(method debug);
use SOAP::Lite;
use MIME::Base64;

#set global variable $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} to workaround the SSL verification restriction
# and modified IO::Socket::SSL.pm to remove the SSL verification alert, got better idea ?

#may need to copy iControlTypeCast.pm from iControl sdk to local /usr/local/lib
BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

    #    push( @INC, "/usr/local/lib" );
}

#use iControlTypeCast;

my $sPort     = "443";
my $sUID      = "admin";
my $sPWD      = "admin";
my $sProtocol = "https";
my $soap_response;
my $timeout = 5;
my @devmembers;

my $help;
my @dgmaddr;
my %dgaddr;
my $adaddr;    #athority device
my $devgroup = "device_group_test";
my $synconly;
my $deletedg;

my $DGT_FAILOVER = "DGT_FAILOVER";
my $DGT_SYNCONLY = "DGT_SYNC_ONLY";

GetOptions(
    "help|h"       => \$help,
    "dgmaddr|d=s"  => \@dgmaddr,
    "adaddr|a=s"   => \$adaddr,
    "devgroup|g:s" => \$devgroup,
    "synconly|s"   => \$synconly,
    "deletedg|dg"  => \$deletedg,
);

sub usage {
    print "Unknown option: @_\n" if (@_);
    print "usage: $0
       --help|-h \t\thelp message
       --dgmaddr|-d \t\tlist of secondary devices -d '<mgmt_ip>:<configsync_ip>:<failover_ip>:<mirror_ip> ; ....'
       --adaddr|-a \t\tthe athority device to build device trust,as -a '<mgmt_ip>:<configsync_ip>:<failover_ip>:<mirror_ip>'
       --devgroup|-g \t\tdevice group name
       --synconly|-s \t\tswitch to create synconly group
       --deletedg|-dg \t\tswitch to delete device group,as '-a <mgmt_ip>' -g <groupname> -dg 

Please note: you must at least have configsync ip item to create device group, failover_ip and mirror_ip can be skipped and configsync
ip will be used as failover_ip and mirror_ip\n";
    exit;
}

usage() if ( defined $help );

my $type = defined $synconly ? $DGT_SYNCONLY : $DGT_FAILOVER;

###setup athority device sync ip, failover ip, mirror ip

my ( $admgmtip, $adsyncip, $adunicastip, $admirrorip ) =
  ( split( /\s*:\s*/, $adaddr ) );

if ( !defined $adunicastip and !defined $synconly ) {
    $adunicastip = $adsyncip;
}

if ( !defined $admirrorip and !defined $synconly ) {
    $admirrorip = $adsyncip;
}

my $adhostname = getHostname($admgmtip) if ( defined $admgmtip );

if ( defined $deletedg ) {
    deleteAllDv( $admgmtip, $devgroup );
    deleteDg( $admgmtip, $devgroup );
    exit;
}

push( @devmembers, $adhostname );

setConfigSyncIP( $admgmtip, $adsyncip, $adhostname );
setUnicastIP( $admgmtip, $adunicastip, $adhostname ) if ( !defined $synconly );
setMirrorIP( $admgmtip, $admirrorip, $adhostname ) if ( !defined $synconly );

# setup each secondary device sync ip, failover ip, mirror ip

@dgmaddr = split( /\s*;\s*/, join( ';', @dgmaddr ) );

foreach my $addr (@dgmaddr) {
    my ( $mgmtip, $configsyncip, $unicastip, $mirrorip ) =
      ( split( /\s*:\s*/, $addr ) );
    my $hostname = getHostname($mgmtip);
    push( @devmembers, $hostname );

    #%dgaddr keyed as mgmtip and value as hash reference
    my $h_ref = $dgaddr{$mgmtip} ||=
      { 'mgmtip' => $mgmtip, 'hostname' => $hostname };
    $h_ref->{'configsyncip'} = $configsyncip;
    if ( defined $unicastip ) {
        $h_ref->{'unicastip'} = $unicastip;
    }
    else {
        $h_ref->{'unicastip'} = $configsyncip if ( !defined $synconly );
    }
    if ( defined $mirrorip ) {
        $h_ref->{'mirrorip'} = $mirrorip;
    }
    else {

        $h_ref->{'mirrorip'} = $configsyncip if ( !defined $synconly );
    }
}

foreach my $mgmtip_href ( values %dgaddr ) {

    my $mgmtip    = $mgmtip_href->{'mgmtip'};
    my $hostname  = $mgmtip_href->{'hostname'};
    my $syncip    = $mgmtip_href->{'configsyncip'};
    my $unicastip = $mgmtip_href->{'unicastip'};
    my $mirrorip  = $mgmtip_href->{'mirrorip'};

    setConfigSyncIP( $mgmtip, $syncip, $hostname );
    setUnicastIP( $mgmtip, $unicastip, $hostname ) if ( !defined $synconly );
    setMirrorIP( $mgmtip, $mirrorip, $hostname ) if ( !defined $synconly );
    buildTrust( $admgmtip, $mgmtip, $hostname );

}

##create device group on athority device

buildDg( $admgmtip, $devgroup ) if ( defined $devgroup );

##add device group members

foreach my $maddr (@devmembers) {

    addDevices( $admgmtip, $maddr, $devgroup );

}

##sync config
print "wait 10 sec to sync the configuration...\n";
sleep 10;
syncConfiguration( $admgmtip, "CONFIGSYNC_ALL", 0 );

# GetInterface
#----------------------------------------------------------------------------
sub GetInterface() {
    my ( $sHost, $module, $name ) = @_;
    my $Interface;

    $Interface =
      SOAP::Lite->uri("urn:iControl:$module/$name")->readable(1)
      ->proxy("$sProtocol://$sHost:$sPort/iControl/iControlPortal.cgi");

   #----------------------------------------------------------------------------
   # Attempt to add auth headers to avoid dual-round trip
   #----------------------------------------------------------------------------

    eval {
        local $SIG{ALRM} = sub { die "timeout" };
        alarm($timeout);

        $Interface->transport->http_request->header( 'Authorization' => 'Basic '
              . MIME::Base64::encode( "$sUID:$sPWD", '' ) );
        alarm(0);
    };

    if ($@) {

        #   warn "caught exception $@: $!";
        return 0;

    }
    else {

        #  warn "no exception $@: $!";
        return $Interface;
    }

}

sub setConfigSyncIP {

    my ( $ip, $syncip, $hostname ) = @_;
    my $sysinet = &GetInterface( "$ip", "Management", "Device" );
    $soap_response = $sysinet->set_configsync_address(
        SOAP::Data->name( devices   => ["$hostname"] ),
        SOAP::Data->name( addresses => ["$syncip"] ),
    );
    &checkResponse($soap_response);

}

sub setUnicastIP {

    my ( $ip, $unicastip, $hostname ) = @_;
    my $sysinet = &GetInterface( "$ip", "Management", "Device" );
    $soap_response = $sysinet->set_unicast_addresses(
        SOAP::Data->name( devices => ["$hostname"] ),
        SOAP::Data->name(
            addresses => [
                [
                    {
                        source => { address => "$unicastip", port => "1026" },
                        effective => { address => "$unicastip", port => "1026" }
                    }
                ]
            ]
        ),
    );
    &checkResponse($soap_response);

}

sub setMirrorIP {
    my ( $ip, $mirrorip, $hostname ) = @_;
    my $sysinet = &GetInterface( "$ip", "Management", "Device" );
    $soap_response = $sysinet->set_primary_mirror_address(
        SOAP::Data->name( devices   => ["$hostname"] ),
        SOAP::Data->name( addresses => [$mirrorip] ),
    );
    &checkResponse($soap_response);
}

sub getHostname {

    my ($ip) = @_;
    my $sysinet = &GetInterface( "$ip", "System", "Inet" );
    $soap_response = $sysinet->get_hostname();
    &checkResponse($soap_response);
    my $hostname = $soap_response->result;
    return $hostname;
}

#----------------------------------------------------------------------------
# checkResponse makes sure the error isn't a SOAP error
#----------------------------------------------------------------------------
sub checkResponse() {
    my ($soap_response) = (@_);
    if ( $soap_response->fault ) {
        print $soap_response->faultcode, " ", $soap_response->faultstring, "\n";
        exit();
    }
}

sub buildTrust {
    my ( $adaddr, $memberip, $member_hostname ) = @_;
    my $dtrmgmt = &GetInterface( "$adaddr", "Management", "Trust" );

    $soap_response = $dtrmgmt->add_authority_device(
        SOAP::Data->name( address                       => "$memberip" ),
        SOAP::Data->name( username                      => "$sUID" ),
        SOAP::Data->name( password                      => "$sPWD" ),
        SOAP::Data->name( device_object_name            => "$member_hostname" ),
        SOAP::Data->name( browser_cert_serial_number    => "" ),
        SOAP::Data->name( browser_cert_signature        => "" ),
        SOAP::Data->name( browser_cert_sha1_fingerprint => "" ),
        SOAP::Data->name( browser_cert_md5_fingerprint  => "" ),
    );
    &checkResponse($soap_response);
}

sub buildDg {
    my ( $adaddr, $devgroup ) = @_;
    my $dgmgmt = &GetInterface( "$adaddr", "Management", "DeviceGroup" );
    $soap_response = $dgmgmt->create(
        SOAP::Data->name( device_groups => ["$devgroup"] ),
        SOAP::Data->name( types         => [$type] ),
    );
    &checkResponse($soap_response);
}

sub addDevices {
    my ( $adaddr, $maddr, $devgroup ) = @_;
    my $dgmgmt = &GetInterface( "$adaddr", "Management", "DeviceGroup" );
    $soap_response = $dgmgmt->add_device(
        SOAP::Data->name( device_groups => ["$devgroup"] ),
        SOAP::Data->name( devices       => [ ["$maddr"] ] ),
    );
    &checkResponse($soap_response);
}

sub deleteDg {
    my ( $adaddr, $devgroup ) = @_;
    my $dgmgmt = &GetInterface( "$adaddr", "Management", "DeviceGroup" );
    $soap_response = $dgmgmt->delete_device_group(
        SOAP::Data->name( device_groups => ["$devgroup"] ),
    );
    &checkResponse($soap_response);
}

sub deleteAllDv {
    my ( $adaddr, $devgroup ) = @_;
    my $dgmgmt = &GetInterface( "$adaddr", "Management", "DeviceGroup" );
    $soap_response = $dgmgmt->remove_all_devices(
        SOAP::Data->name( device_groups => ["$devgroup"] ),
    );
    &checkResponse($soap_response);
}

#----------------------------------------------------------------------------
# sub syncConfiguration
#----------------------------------------------------------------------------
sub syncConfiguration {
    my ( $adaddr, $syncFlag, $quiet ) = (@_);

    my $success = 0;

    my $configsync = &GetInterface( "$adaddr", "System", "ConfigSync" );

    $soap_response = $configsync->synchronize_configuration(
        SOAP::Data->name( sync_flag => $syncFlag ) );
    if ( $soap_response->fault ) {
        if ( 1 != $quiet ) {
            print $soap_response->faultcode, " ", $soap_response->faultstring,
              "\n";
        }
    }
    else {
        $success = 1;
        if ( 1 != $quiet ) {
            print "Configuration synchronized successfully!\n";
        }
    }
    return $success;
}

